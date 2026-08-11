# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New API v2 Resources' do
  let(:api_host) { 'https://test.conexa.app' }
  let(:api_base) { "#{api_host}/index.php/api/v2" }

  around(:each) do |example|
    VCR.turned_off do
      WebMock.enable!
      example.run
    end
  end

  before(:each) do
    Conexa.configure do |c|
      c.api_token = 'test_token'
      c.api_host = api_host
    end
  end

  # ---------------------------------------------------------------------------
  # M3 - Integration tests for new resources
  # ---------------------------------------------------------------------------

  describe Conexa::ReceivingMethod do
    describe '.all' do
      it 'lists receiving methods' do
        stub_request(:get, "#{api_base}/receivingMethods")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { receivingMethodId: 10, name: 'Dinheiro', isActive: true },
                { receivingMethodId: 11, name: 'Cartao de Credito', isActive: true }
              ],
              pagination: { limit: 10, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::ReceivingMethod.all(limit: 10)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(2)
        expect(result.data.first.name).to eq('Dinheiro')
        expect(result.data.last.name).to eq('Cartao de Credito')
        expect(result.pagination.has_next).to be false
      end
    end

    describe '.find' do
      it 'finds a receiving method by id' do
        stub_request(:get, "#{api_base}/receivingMethod/10")
          .to_return(
            status: 200,
            body: { receivingMethodId: 10, name: 'Dinheiro', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        method = Conexa::ReceivingMethod.find(10)

        expect(method.name).to eq('Dinheiro')
        expect(method.is_active).to be true
      end
    end
  end

  describe Conexa::PaymentMethod do
    describe '.all' do
      it 'lists payment methods' do
        stub_request(:get, "#{api_base}/paymentMethods")
          .with(query: hash_including({ 'limit' => '20', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ paymentMethodId: 1, name: 'Boleto', isActive: true }],
              pagination: { limit: 20, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::PaymentMethod.all(limit: 20)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(1)
        expect(result.data.first.name).to eq('Boleto')
      end
    end

    describe '.find' do
      it 'finds a payment method by id' do
        stub_request(:get, "#{api_base}/paymentMethod/1")
          .to_return(
            status: 200,
            body: { paymentMethodId: 1, name: 'Boleto', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        method = Conexa::PaymentMethod.find(1)

        expect(method.name).to eq('Boleto')
      end
    end
  end

  describe Conexa::BillCategory do
    describe '.all' do
      it 'lists bill categories' do
        stub_request(:get, "#{api_base}/billCategories")
          .with(query: hash_including({ 'limit' => '20', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { billCategoryId: 4, name: 'Impostos' },
                { billCategoryId: 5, name: 'Folha de Pagamento' }
              ],
              pagination: { limit: 20, offset: 0, hasNext: true }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::BillCategory.all(limit: 20)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(2)
        expect(result.data.first.name).to eq('Impostos')
        expect(result.pagination.has_next).to be true
      end
    end

    describe '.find' do
      it 'finds a bill category by id' do
        stub_request(:get, "#{api_base}/billCategory/4")
          .to_return(
            status: 200,
            body: { billCategoryId: 4, name: 'Impostos' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        category = Conexa::BillCategory.find(4)

        expect(category.name).to eq('Impostos')
      end
    end
  end

  describe Conexa::BillSubcategory do
    describe '.all' do
      it 'lists bill subcategories' do
        stub_request(:get, "#{api_base}/billSubcategories")
          .with(query: hash_including({ 'limit' => '15', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ billSubcategoryId: 12, name: 'ISS', billCategoryId: 4 }],
              pagination: { limit: 15, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::BillSubcategory.all(limit: 15)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(1)
        expect(result.data.first.name).to eq('ISS')
      end
    end

    describe '.find' do
      it 'finds a bill subcategory by id' do
        stub_request(:get, "#{api_base}/billSubcategory/12")
          .to_return(
            status: 200,
            body: { billSubcategoryId: 12, name: 'ISS', billCategoryId: 4 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        subcategory = Conexa::BillSubcategory.find(12)

        expect(subcategory.name).to eq('ISS')
      end
    end
  end

  describe Conexa::CostCenter do
    describe '.all' do
      it 'lists cost centers' do
        stub_request(:get, "#{api_base}/costCenters")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ costCenterId: 7, name: 'Administrativo', isActive: true }],
              pagination: { limit: 10, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::CostCenter.all(limit: 10)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(1)
        expect(result.data.first.name).to eq('Administrativo')
      end
    end

    describe '.find' do
      it 'finds a cost center by id' do
        stub_request(:get, "#{api_base}/costCenter/7")
          .to_return(
            status: 200,
            body: { costCenterId: 7, name: 'Administrativo', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        cost_center = Conexa::CostCenter.find(7)

        expect(cost_center.name).to eq('Administrativo')
        expect(cost_center.is_active).to be true
      end
    end
  end

  describe Conexa::Account do
    describe '.all' do
      it 'lists accounts' do
        stub_request(:get, "#{api_base}/accounts")
          .with(query: hash_including({ 'limit' => '50', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { accountId: 1, name: 'Banco do Brasil', isActive: true },
                { accountId: 2, name: 'Caixa Economica', isActive: true }
              ],
              pagination: { limit: 50, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Account.all(limit: 50)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(2)
        expect(result.data.first.name).to eq('Banco do Brasil')
        expect(result.data.last.name).to eq('Caixa Economica')
      end
    end

    describe '.find' do
      it 'finds an account by id' do
        stub_request(:get, "#{api_base}/account/1")
          .to_return(
            status: 200,
            body: { accountId: 1, name: 'Banco do Brasil', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        account = Conexa::Account.find(1)

        expect(account.name).to eq('Banco do Brasil')
      end
    end
  end

  describe Conexa::ServiceCategory do
    describe '.all' do
      it 'lists service categories' do
        stub_request(:get, "#{api_base}/serviceCategories")
          .with(query: hash_including({ 'limit' => '25', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ serviceCategoryId: 3, name: 'Consultoria' }],
              pagination: { limit: 25, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::ServiceCategory.all(limit: 25)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(1)
        expect(result.data.first.name).to eq('Consultoria')
      end
    end

    describe '.find' do
      it 'finds a service category by id' do
        stub_request(:get, "#{api_base}/serviceCategory/3")
          .to_return(
            status: 200,
            body: { serviceCategoryId: 3, name: 'Consultoria' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        category = Conexa::ServiceCategory.find(3)

        expect(category.name).to eq('Consultoria')
      end
    end
  end

  describe Conexa::RoomBooking do
    describe '.all' do
      it 'lists room bookings via /room/bookings' do
        stub_request(:get, "#{api_base}/room/bookings")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { bookingId: 143063, roomId: 5, customerId: 127, status: 'confirmed' },
                { bookingId: 143064, roomId: 6, customerId: 200, status: 'pending' }
              ],
              pagination: { limit: 10, offset: 0, hasNext: true }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::RoomBooking.all(limit: 10)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(2)
        expect(result.data.first.status).to eq('confirmed')
        expect(result.pagination.has_next).to be true
      end
    end

    describe '.find' do
      it 'finds a room booking via /room/booking/:id' do
        stub_request(:get, "#{api_base}/room/booking/143063")
          .to_return(
            status: 200,
            body: { bookingId: 143063, roomId: 5, customerId: 127, status: 'confirmed' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        booking = Conexa::RoomBooking.find(143063)

        expect(booking.room_id).to eq(5)
        expect(booking.customer_id).to eq(127)
        expect(booking.status).to eq('confirmed')
      end
    end
  end

  describe Conexa::Product do
    describe '.all' do
      it 'lists products' do
        stub_request(:get, "#{api_base}/products")
          .with(query: hash_including({ 'limit' => '30', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { productId: 100, name: 'Mensalidade', isActive: true },
                { productId: 101, name: 'Taxa de Matricula', isActive: true }
              ],
              pagination: { limit: 30, offset: 0, hasNext: false }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Product.all(limit: 30)

        expect(result).to be_a(Conexa::Result)
        expect(result.data.size).to eq(2)
        expect(result.data.first.name).to eq('Mensalidade')
        expect(result.data.last.name).to eq('Taxa de Matricula')
      end
    end

    describe '.find' do
      it 'finds a product by id' do
        stub_request(:get, "#{api_base}/product/100")
          .to_return(
            status: 200,
            body: { productId: 100, name: 'Mensalidade', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        product = Conexa::Product.find(100)

        expect(product.name).to eq('Mensalidade')
        expect(product.is_active).to be true
      end
    end

    describe '.create' do
      it 'creates a product via POST /product' do
        stub_request(:post, "#{api_base}/product")
          .to_return(
            status: 200,
            body: { id: 200 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "#{api_base}/product/200")
          .to_return(
            status: 200,
            body: { productId: 200, name: 'Novo Produto', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        product = Conexa::Product.create(name: 'Novo Produto', company_id: 3)

        expect(product.name).to eq('Novo Produto')
        expect(product.product_id).to eq(200)
      end
    end

    describe '.destroy' do
      it 'deletes a product via DELETE /product/:id' do
        stub_request(:get, "#{api_base}/product/100")
          .to_return(
            status: 200,
            body: { productId: 100, name: 'Mensalidade', isActive: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:delete, "#{api_base}/product/100")
          .to_return(
            status: 200,
            body: { productId: 100, name: 'Mensalidade', isActive: false }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Product.destroy(100)

        expect(result).to be_truthy
      end
    end
  end

  # ---------------------------------------------------------------------------
  # M4 - Legacy pagination compatibility with next_page / has_next?
  # ---------------------------------------------------------------------------

  describe 'Legacy pagination compatibility' do
    describe '#has_next?' do
      it 'returns false when API returns legacy pagination format (page/size/total)' do
        stub_request(:get, "#{api_base}/customers")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ customerId: 1, name: 'Customer 1' }],
              pagination: { page: 1, size: 10, total: 1 }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Customer.all(limit: 10)

        expect(result.has_next?).to be false
      end

      it 'returns false when pagination has no hasNext field at all' do
        stub_request(:get, "#{api_base}/customers")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ customerId: 1, name: 'Customer 1' }],
              pagination: { page: 1, size: 10 }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Customer.all(limit: 10)

        expect(result.has_next?).to be false
      end
    end

    describe '#next_page' do
      it 'raises StopIteration when pagination does not have hasNext' do
        stub_request(:get, "#{api_base}/customers")
          .with(query: hash_including({ 'limit' => '10', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [{ customerId: 1, name: 'Customer 1' }],
              pagination: { page: 1, size: 10, total: 1 }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Customer.all(limit: 10)

        expect { result.next_page }.to raise_error(StopIteration, 'No more pages')
      end

      it 'raises StopIteration when legacy pagination has total equal to current count' do
        stub_request(:get, "#{api_base}/customers")
          .with(query: hash_including({ 'limit' => '50', 'offset' => '0' }))
          .to_return(
            status: 200,
            body: {
              data: [
                { customerId: 1, name: 'Customer 1' },
                { customerId: 2, name: 'Customer 2' }
              ],
              pagination: { page: 1, size: 50, total: 2 }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        result = Conexa::Customer.all(limit: 50)

        expect(result.has_next?).to be false
        expect { result.next_page }.to raise_error(StopIteration, 'No more pages')
      end
    end
  end
end
