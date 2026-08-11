# frozen_string_literal: true

# Captures the request the gem actually emits, instead of stubbing the one we
# expect it to emit.
#
# This inversion is the point. Every HTTP stub in this suite was written by
# reading the implementation, so a stub agrees with the code even when the code
# disagrees with the API — a wrong verb, a wrong field name and a wrong URL all
# passed for months. Asserting on the captured request is what makes those
# visible.
#
# @example
#   sent = capture_requests { Conexa::Charge.settle(555) }
#   expect(sent.last.method).to eq(:patch)
#   expect(JSON.parse(sent.last.body)).to eq({ "settlementDate" => "2026-08-11" })
module RequestCapture
  # @param status [Integer] status returned to every captured request
  # @param body [String, nil] body returned to every captured request. When nil,
  #   the stub echoes back the last numeric segment of the path as `id`, so the
  #   `find(id)` that class-level action helpers perform first yields an object
  #   with a usable primary key (Model#id falls back to attributes['id']).
  # @return [Array<WebMock::RequestSignature>] every request emitted in the block,
  #   in order. The request under test is usually `sent.last`.
  def capture_requests(status: 200, body: nil)
    sent = []
    stub_request(:any, /\.conexa\.app/)
      .with { |request| sent << request; true }
      .to_return do |request|
        { status: status,
          body: body || %({"data":{"id":#{request.uri.path[%r{/(\d+)(?:/[^/]*)?\z}, 1] || "null"}}}),
          headers: { "Content-Type" => "application/json" } }
      end
    yield
    sent
  end

  # Convenience for the common case of one action request.
  # @return [WebMock::RequestSignature]
  def capture_request(**opts, &block)
    capture_requests(**opts, &block).last
  end

  # The JSON body of a captured request, as a Hash.
  def sent_payload(request)
    JSON.parse(request.body.to_s)
  end
end
