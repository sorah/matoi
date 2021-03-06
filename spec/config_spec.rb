require 'spec_helper'
require 'oauth'
require 'groonga'
require 'matoi/config'

describe Matoi::Config, groonga: false do
  let(:config_hash) do
    {
      "token_file" => "token.yml",
      "db_path"    => "tweets_db",
      "consumer"   => {
        "token"  => 'THE_CONSUMER',
        "secret" => 'THE_CONSUMER_SECRET',
      }
    }
  end

  let(:base_path) { File.expand_path File.join(__FILE__, '..', 'fixtures') }
  subject(:config) { described_class.new(config_hash, base_path) }

  describe "#consumer" do
    subject { config.consumer }

    it "returns OAuth::Consumer" do
      subject.should be_a_kind_of(OAuth::Consumer)
      subject.key.should == 'THE_CONSUMER'
      subject.secret.should == 'THE_CONSUMER_SECRET'
      subject.site.should == 'https://api.twitter.com/'
    end
  end

  describe "#access_token" do
    before do
      config.should_receive(:credentials).at_least(:once).and_return(
        'user' => {token: 'THE_ACCESS_KEY', secret: 'THE_ACCESS_SECRET'}
      )
    end

    subject { config.access_token('user') }

    it "returns AccessToken" do
      subject.should be_a_kind_of(OAuth::AccessToken)
      subject.token.should == 'THE_ACCESS_KEY'
      subject.secret.should == 'THE_ACCESS_SECRET'
      subject.consumer.should == config.consumer
    end
  end

#  describe "#credentials" do
#    subject { config.credentials }
#    it { should == {'user' token: 'THE_ACCESS_KEY', secret: 'THE_ACCESS_SECRET'} }
#  end

  describe "#credential_for_stream" do
    before do
      config.should_receive(:credentials).at_least(:once).and_return(
        'user' => {token: 'THE_ACCESS_KEY', secret: 'THE_ACCESS_SECRET'}
      )
    end

    subject { config.credential_for_stream('user') }

    it { should == \
      {
        consumer_key:    'THE_CONSUMER',
        consumer_secret: 'THE_CONSUMER_SECRET',
        access_key:      'THE_ACCESS_KEY',
        access_secret:   'THE_ACCESS_SECRET',
      }
    }
  end

  describe "#open_db" do
    let(:db_path) { File.expand_path File.join(base_path, "tweets_db") }
    context "if database exists" do
      before do
        File.should_receive(:exists?).with(db_path).and_return(true)
      end

      it "opens db", groonga: :dir do
        Groonga::Database.should_receive(:open).with(db_path) do
          Groonga::Database.create(path: File.join(@tmpdir, 'db'))
        end
        subject.open_db
      end
    end

    context "if database not exists" do
      before do
        File.should_receive(:exists?).with(db_path).and_return(false)
      end

      it "opens db", groonga: :dir do
        Groonga::Database.should_receive(:create).with(path: db_path) do
          Groonga::Database.create_orig(path: File.join(@tmpdir, 'db'))
        end
        subject.open_db
      end
    end
  end

  describe "#add_credential" do
    # def add_credential(screen_name, token, secret)
    it "saves new credential to file" do
      new_credentials_yml = config.credentials.dup.tap { |c|
        c['foo'] = {token: 'a', secret: 'b'}
      }.to_yaml

      File.should_receive(:write).with(config.token_file, new_credentials_yml)

      config.add_credential('foo', 'a', 'b')
    end
  end
end
