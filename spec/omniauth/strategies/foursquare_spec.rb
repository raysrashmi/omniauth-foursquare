require 'spec_helper'
require 'omniauth-foursquare'

describe OmniAuth::Strategies::Foursquare do
  before :each do
    @request = double('Request')
    allow(@request).to receive(:params) { {} }
  end

  subject do
    OmniAuth::Strategies::Foursquare.new(nil, @options || {}).tap do |strategy|
      allow(strategy).to receive(:request) { @request }
    end
  end

  it_should_behave_like 'an oauth2 strategy'

  describe '#client' do
    it 'has correct Foursquare site' do
      expect(subject.client.site).to eq('https://foursquare.com')
    end

    it 'has correct authorize url' do
      expect(subject.client.options[:authorize_url]).to eq('/oauth2/authenticate')
    end

    it 'has correct token url' do
      expect(subject.client.options[:token_url]).to eq('/oauth2/access_token')
    end
  end

  describe '#info' do
    before :each do
      @raw_info = {
        'firstName' => 'Fred',
        'lastName' => 'Smith',
        'contact' => {
          'email' => 'fred@example.com',
          'phone' => '+1 555 555-5555',
        },
        'photo' => 'https://img-s.foursquare.com/userpix_thumbs/blank_boy.jpg',
        'homeCity' => 'Chicago',
        'bio' => 'I am a guy from Chicago.'
      }
      allow(subject).to receive(:raw_info) { @raw_info }
    end

    context 'when data is present in raw info' do
      it 'returns the combined name' do
        expect(subject.info[:name]).to eq('Fred Smith')
      end

      it 'returns the first name' do
        expect(subject.info[:first_name]).to eq('Fred')
      end

      it 'returns the last name' do
        expect(subject.info[:last_name]).to eq('Smith')
      end

      it 'returns the email' do
        expect(subject.info[:email]).to eq('fred@example.com')
      end

      it 'returns the phone number' do
        expect(subject.info[:phone]).to eq('+1 555 555-5555')
      end

      it "sets the email blank if contact block is missing in raw_info" do
        @raw_info.delete('contact')
        expect(subject.info[:email]).to be_nil
      end

      it 'returns the user image' do
        expect(subject.info[:image]).to eq('https://img-s.foursquare.com/userpix_thumbs/blank_boy.jpg')
      end

      it 'returns the user location' do
        expect(subject.info[:location]).to eq('Chicago')
      end

      it 'returns the user description' do
        expect(subject.info[:description]).to eq('I am a guy from Chicago.')
      end
    end
  end

  describe '#credentials' do
    before :each do
      @access_token = double('OAuth2::AccessToken')
      allow(@access_token).to receive(:token)
      allow(@access_token).to receive(:expires?)
      allow(@access_token).to receive(:expires_at)
      allow(@access_token).to receive(:refresh_token)
      allow(subject).to receive(:access_token) { @access_token }
    end

    it 'returns a Hash' do
      expect(subject.credentials).to be_a(Hash)
    end

    it 'returns the token' do
      allow(@access_token).to receive(:token) { '123' }
      expect(subject.credentials['token']).to eq('123')
    end

    it 'returns the expiry status' do
      allow(@access_token).to receive(:expires?) { true }
      expect(subject.credentials['expires']).to eq(true)

      allow(@access_token).to receive(:expires?) { false }
      expect(subject.credentials['expires']).to eq(false)
    end

    it 'returns the refresh token and expiry time when expiring' do
      ten_mins_from_now = (Time.now + 360).to_i
      allow(@access_token).to receive(:expires?) { true }
      allow(@access_token).to receive(:refresh_token) { '321' }
      allow(@access_token).to receive(:expires_at) { ten_mins_from_now }
      expect(subject.credentials['refresh_token']).to eq('321')
      expect(subject.credentials['expires_at']).to eq(ten_mins_from_now)
    end

    it 'does not return the refresh token when it is nil and expiring' do
      allow(@access_token).to receive(:expires?) { true }
      allow(@access_token).to receive(:refresh_token) { nil }
      expect(subject.credentials['refresh_token']).to be_nil
      expect(subject.credentials).not_to have_key('refresh_token')
    end

    it 'does not return the refresh token when not expiring' do
      allow(@access_token).to receive(:expires?) { false }
      allow(@access_token).to receive(:refresh_token) { 'XXX' }
      expect(subject.credentials['refresh_token']).to be_nil
      expect(subject.credentials).not_to have_key('refresh_token')
    end
  end
end
