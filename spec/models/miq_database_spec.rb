describe MiqDatabase do
  context ".seed" do
    include_examples ".seed called multiple times"

    context "default values" do
      it "new record" do
        db = MiqDatabase.seed
        expect(db.csrf_secret_token_encrypted).to be_encrypted
        expect(db.session_secret_token_encrypted).to be_encrypted
        expect(db.update_repo_name).to eq("cf-me-5.5-for-rhel-7-rpms rhel-server-rhscl-7-rpms")
        expect(db.registration_type).to eq("sm_hosted")
        expect(db.registration_server).to eq("subscription.rhn.redhat.com")
      end

      context "existing record" do
        it "will seed nil values" do
          FactoryGirl.build(:miq_database,
                            :csrf_secret_token    => nil,
                            :session_secret_token => nil,
                            :update_repo_name     => nil
                           ).save(:validate => false)

          db = MiqDatabase.seed
          expect(db.csrf_secret_token_encrypted).to be_encrypted
          expect(db.session_secret_token_encrypted).to be_encrypted
          expect(db.update_repo_name).to eq("cf-me-5.5-for-rhel-7-rpms rhel-server-rhscl-7-rpms")
        end

        it "will not change existing values" do
          FactoryGirl.create(:miq_database,
                             :csrf_secret_token    => "abc",
                             :session_secret_token => "def",
                             :update_repo_name     => "ghi"
                            )
          csrf, session, update_repo = MiqDatabase.all.collect { |db| [db.csrf_secret_token, db.session_secret_token, db.update_repo_name] }.first

          db = MiqDatabase.seed
          expect(db.csrf_secret_token).to eq(csrf)
          expect(db.session_secret_token).to eq(session)
          expect(db.update_repo_name).to eq(update_repo)
        end
      end
    end

    context "registration_default_values" do
      it "registration_default_values method" do
        expect(MiqDatabase.registration_default_values).to be_kind_of(Hash)
      end

      it "can not be modified" do
        defaults = MiqDatabase.registration_default_values
        expect { defaults[:registration_type] = "abc" }.to raise_error(RuntimeError)
      end
    end
  end

  context "verify_credentials" do
    it "verify registration credentials" do
      MiqDatabase.seed
      EvmSpecHelper.create_guid_miq_server_zone

      expect(MiqTask).to receive(:wait_for_taskid).and_return(FactoryGirl.create(:miq_task, :state => "Finished"))

      MiqDatabase.first.verify_credentials(:registration)
    end
  end

  context "#registration_organization_name" do
    it "returns registration_organization when registration_organization_display_name is not available" do
      db = FactoryGirl.create(:miq_database, :registration_organization => "foo")
      expect(db.registration_organization_name).to eq("foo")
    end

    it "returns registration_organization_display_name when available" do
      db = FactoryGirl.create(:miq_database,
                              :registration_organization              => "foo",
                              :registration_organization_display_name => "FOO")
      expect(db.registration_organization_name).to eq("FOO")
    end
  end

  if ENV.key?("CI")
    it "uses region 1 on travis" do
      expect(MiqDatabase.seed.my_region_number).to eq(1)
    end
  end
end
