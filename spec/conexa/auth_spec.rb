require 'spec_helper'
require 'conexa'

module Conexa
  RSpec.describe Auth do
    before(:each) do
      Conexa.configure do |c|
        c.api_host = "https://test.conexa.app"
      end
    end

    describe 'POST /auth' do
      context 'successful authentication' do
        it 'authenticates admin user successfully' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            expect(auth).to be_a(Conexa::Auth)

            # Validar campo user (ConexaObject nested)
            expect(auth.user).not_to be_nil
            expect(auth.user.id).to eq(1)
            expect(auth.user.type).to eq('admin')
            expect(auth.user.name).to eq('Luke Skywalker')

            # Validar campos de token (snake_case via ConexaObject)
            expect(auth.token_type).to eq('Bearer')
            expect(auth.access_token).to be_a(String)
            expect(auth.access_token).not_to be_empty

            # Validar expiração
            expect(auth.expires_in).to eq(28800)

            # Validar que access_token é um JWT válido (formato básico)
            expect(auth.access_token).to match(/^[\w-]+\.[\w-]+\.[\w-]+$/)
          end
        end

        it 'authenticates employee user successfully' do
          VCR.use_cassette('auth/employee_success') do
            auth = Conexa::Auth.authenticate(
              username: 'employee@company.com',
              password: 'test_password'
            )

            expect(auth).to be_a(Conexa::Auth)
            expect(auth.user.type).to eq('employee')
            expect(auth.user.id).to eq(534)
            expect(auth.user.name).to eq('Han Solo')
            expect(auth.token_type).to eq('Bearer')
            expect(auth.access_token).to be_a(String)
            expect(auth.expires_in).to eq(28800)
          end
        end

        it 'returns valid JWT token that can be decoded' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            token = auth.access_token

            # JWT é composto de: header.payload.signature
            parts = token.split('.')
            expect(parts.length).to eq(3)

            # Payload deve ser JSON válido quando decodificado de Base64
            require 'base64'
            require 'json'

            payload_base64 = parts[1]
            payload_base64 += '=' * (4 - payload_base64.length % 4) if payload_base64.length % 4 != 0

            payload = JSON.parse(Base64.urlsafe_decode64(payload_base64))

            expect(payload).to have_key('data')
            expect(payload['data']).to have_key('id')
            expect(payload['data']).to have_key('type')
          end
        end
      end

      context 'validation errors' do
        it 'raises ResponseError when password is empty' do
          VCR.use_cassette('auth/password_empty_error') do
            expect {
              Conexa::Auth.authenticate(
                username: 'admin',
                password: ''
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end

        it 'raises ResponseError when username is missing' do
          VCR.use_cassette('auth/username_missing_error') do
            expect {
              Conexa::Auth.authenticate(
                username: nil,
                password: 'test_password'
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end

        it 'raises ResponseError when password is missing' do
          VCR.use_cassette('auth/password_missing_error') do
            expect {
              Conexa::Auth.authenticate(
                username: 'admin',
                password: nil
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end
      end

      context 'authentication errors' do
        it 'raises ResponseError when password is invalid' do
          VCR.use_cassette('auth/invalid_password_error') do
            expect {
              Conexa::Auth.authenticate(
                username: 'admin',
                password: 'wrong_password'
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end

        it 'raises ResponseError when user does not exist' do
          VCR.use_cassette('auth/user_not_found_error') do
            expect {
              Conexa::Auth.authenticate(
                username: 'nonexistent_user',
                password: 'test_password'
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end

        it 'raises ResponseError when user is temporarily blocked' do
          VCR.use_cassette('auth/user_blocked_error') do
            expect {
              Conexa::Auth.authenticate(
                username: 'blocked_user',
                password: 'test_password'
              )
            }.to raise_error(Conexa::ResponseError)
          end
        end
      end

      context 'token management' do
        it 'allows using returned token for subsequent requests' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            token = auth.access_token

            # Configurar gem para usar o token retornado
            Conexa.configure do |c|
              c.api_token = token
              c.api_host = "https://test.conexa.app"
            end

            expect(Conexa.configuration.api_token).to eq(token)
          end
        end

        it 'stores user information from authentication response' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            expect(auth.user.id).to be > 0
            expect(['admin', 'employee']).to include(auth.user.type)
            expect(auth.user.name).to be_a(String)
            expect(auth.user.name.length).to be > 0
          end
        end
      end

      context 'response validation' do
        it 'validates all required fields are present in success response' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            # Campos obrigatórios (snake_case via ConexaObject)
            expect(auth.user).not_to be_nil
            expect(auth.token_type).not_to be_nil
            expect(auth.access_token).not_to be_nil
            expect(auth.expires_in).not_to be_nil

            # Campos obrigatórios do user
            expect(auth.user.id).not_to be_nil
            expect(auth.user.type).not_to be_nil
            expect(auth.user.name).not_to be_nil
          end
        end

        it 'validates expiresIn is 8 hours (28800 seconds)' do
          VCR.use_cassette('auth/admin_success') do
            auth = Conexa::Auth.authenticate(
              username: 'admin',
              password: 'test_password'
            )

            expect(auth.expires_in).to eq(28800)
          end
        end
      end
    end
  end
end
