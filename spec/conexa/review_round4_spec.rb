# frozen_string_literal: true

require "spec_helper"

# Fourth review round. Round three fixed `ConexaObject#update` for a nil argument,
# which is what an empty body produces — but `Request#call` has two other shapes
# it can return, and neither was covered. Same class of bug, one level out again.
RSpec.describe "review round 4" do
  let(:base) { "https://test.conexa.app/index.php/api/v2" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "responses that cannot update an object" do
    # `Request#run` explicitly handles a top-level array, and ConexaObject.convert
    # passes arrays and scalars straight through — so update can still be handed
    # something with no #to_hash.
    it "does not raise when a delete answers with an array" do
      stub_request(:delete, "#{base}/sale/1").to_return(status: 200, body: "[1,2]", headers: json)

      expect { Conexa::Sale.destroy(1) }.not_to raise_error
    end

    it "does not raise when a create answers with a scalar" do
      stub_request(:post, "#{base}/sale").to_return(status: 201, body: "true", headers: json)

      expect { Conexa::Sale.create(notes: "x") }.not_to raise_error
    end

    # The nastiest of the set: `removed_attributes` deletes every key absent from
    # the incoming hash, so a bare `{}` wiped the whole object — primary key
    # included — and reported success.
    it "keeps the object intact when a save answers with an empty object" do
      stub_request(:get, "#{base}/charge/9").to_return(
        status: 200, body: '{"data":{"chargeId":9,"status":"pending"}}', headers: json
      )
      stub_request(:patch, "#{base}/charge/9").to_return(status: 200, body: "{}", headers: json)

      charge = Conexa::Charge.find(9)
      charge.status = "paid"
      charge.save

      expect(charge.charge_id).to eq(9)
      expect(charge.attributes).not_to be_empty
    end

    it "still replaces attributes from a full representation" do
      stub_request(:get, "#{base}/charge/9").to_return(
        status: 200, body: '{"data":{"chargeId":9,"status":"pending","notes":"old"}}', headers: json
      )
      stub_request(:patch, "#{base}/charge/9").to_return(
        status: 200, body: '{"data":{"chargeId":9,"status":"paid"}}', headers: json
      )

      charge = Conexa::Charge.find(9)
      charge.status = "paid"
      charge.save

      expect(charge.status).to eq("paid")
      expect(charge.notes).to be_nil
    end
  end

  # #destroy guards a blank id; #save did not, so an object left id-less issued
  # PATCH /customer/ instead of failing fast.
  describe "writing without an id" do
    it "raises rather than requesting a path with an empty id segment" do
      customer = Conexa::Customer.new({})
      customer.name = "x"

      expect { customer.save }.to raise_error(Conexa::RequestError, /Invalid ID/)
    end
  end

  describe Conexa::Result do
    it "raises a Conexa error, not TypeError, when pagination has no limit" do
      stub_request(:get, %r{#{Regexp.escape(base)}/charges}).to_return(
        status: 200,
        body: '{"data":[{"chargeId":1}],"pagination":{"offset":0,"hasNext":true}}',
        headers: json
      )

      expect { Conexa::Charge.all(limit: 5).next_page }.to raise_error(Conexa::ConexaError)
    end
  end

  describe Conexa::ValidationError do
    subject(:error) do
      stub_request(:get, "#{base}/customer/2").to_return(
        status: 400, body: '{"status":"error"}', headers: json
      )
      begin
        Conexa::Customer.find(2)
      rescue Conexa::ConexaError => e
        e
      end
    end

    it "carries something more useful than its own class name" do
      expect(error.message).not_to eq("Conexa::ValidationError")
    end

    it "does not raise from #to_h when there were no param errors" do
      expect { error.to_h }.not_to raise_error
    end
  end

  describe "exception messages" do
    it "omits the errors suffix when the API sent no errors array" do
      stub_request(:get, "#{base}/customer/3").to_return(
        status: 403,
        body: '{"message":"You are not authorized to perform this action."}',
        headers: json
      )

      expect { Conexa::Customer.find(3) }.to raise_error(Conexa::ResponseError) { |e|
        expect(e.message).to include("You are not authorized")
        expect(e.message).not_to include("Erros:")
      }
    end

    it "renders errors as readable text rather than a Ruby literal" do
      stub_request(:get, "#{base}/customer/4").to_return(
        status: 422,
        body: '{"message":"It was not possible to process your request",' \
              '"errors":[{"code":"CHARGE_11","message":"Only open charges can be settled."}]}',
        headers: json
      )

      expect { Conexa::Customer.find(4) }.to raise_error(Conexa::ResponseError) { |e|
        expect(e.message).to include("CHARGE_11: Only open charges can be settled.")
        # No Ruby inspect dump of the errors array. The `=>` separating the HTTP
        # status from the API message is ResponseError's own formatting and stays.
        expect(e.message).not_to include('"code"=>')
        expect(e.message).not_to include("Erros:")
      }
    end
  end
end
