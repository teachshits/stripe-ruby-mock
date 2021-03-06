require 'spec_helper'

def expect_card_error(code, param)
  expect { Stripe::Charge.create() }.to raise_error {|e|
    expect(e).to be_a(Stripe::CardError)
    expect(e.http_status).to eq(402)
    expect(e.code).to eq(code)
    expect(e.param).to eq(param)
  }
end

shared_examples 'Stripe Error Mocking' do

  it "mocks a manually given stripe card error" do
    error = Stripe::CardError.new('Test Msg', 'param_name', 'bad_code', 444, 'body', 'json body')
    StripeMock.prepare_error(error)

    expect { Stripe::Customer.create() }.to raise_error {|e|
      expect(e).to be_a(Stripe::CardError)
      expect(e.code).to eq('bad_code')
      expect(e.param).to eq('param_name')
      expect(e.message).to eq('Test Msg')

      expect(e.http_status).to eq(444)
      expect(e.http_body).to eq('body')
      expect(e.json_body).to eq('json body')
    }
  end


  it "mocks a manually gives stripe invalid request error" do

    error = Stripe::InvalidRequestError.new('Test Invalid', 'param', 987, 'ibody', 'json ibody')
    StripeMock.prepare_error(error)

    expect { Stripe::Charge.create() }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.param).to eq('param')
      expect(e.message).to eq('Test Invalid')

      expect(e.http_status).to eq(987)
      expect(e.http_body).to eq('ibody')
      expect(e.json_body).to eq('json ibody')
    }
  end


  it "mocks a manually gives stripe invalid auth error" do
    error = Stripe::AuthenticationError.new('Bad Auth', 499, 'abody', 'json abody')
    StripeMock.prepare_error(error)

    expect { Stripe::Plan.create() }.to raise_error {|e|
      expect(e).to be_a(Stripe::AuthenticationError)
      expect(e.message).to eq('Bad Auth')

      expect(e.http_status).to eq(499)
      expect(e.http_body).to eq('abody')
      expect(e.json_body).to eq('json abody')
    }
  end


  it "raises a custom error for specific actions" do
    custom_error = StandardError.new("Please knock first.")
    StripeMock.prepare_error(custom_error, :new_customer)

    expect { Stripe::Charge.create }.to_not raise_error
    expect { Stripe::Customer.create }.to raise_error {|e|
      expect(e).to be_a StandardError
      expect(e.message).to eq("Please knock first.")
    }
  end

  # # # # # # # # # # # # # #
  # Card Error Helper Methods
  # # # # # # # # # # # # # #

  it "raises an error for an unrecognized card error code" do
    expect { StripeMock.prepare_card_error(:non_existant_error_code) }.to raise_error {|e|
      expect(e).to be_a(StripeMock::StripeMockError)
    }
  end

  it "only raises a card error when a card charge is attempted" do
    StripeMock.prepare_card_error(:card_declined)
    expect { Stripe::Customer.create(id: 'x') }.to_not raise_error
    expect { Stripe::Charge.create() }.to raise_error Stripe::CardError
  end

  it "mocks an incorrect number card error" do
    StripeMock.prepare_card_error(:incorrect_number)
    expect_card_error 'incorrect_number', 'number'
  end

  it "mocks an invalid number card error" do
    StripeMock.prepare_card_error(:invalid_number)
    expect_card_error 'invalid_number', 'number'
  end

  it "mocks an invalid expiration month card error" do
    StripeMock.prepare_card_error(:invalid_expiry_month)
    expect_card_error 'invalid_expiry_month', 'exp_month'
  end

  it "mocks an invalid expiration year card error" do
    StripeMock.prepare_card_error(:invalid_expiry_year)
    expect_card_error 'invalid_expiry_year', 'exp_year'
  end

  it "mocks an invalid cvc card error" do
    StripeMock.prepare_card_error(:invalid_cvc)
    expect_card_error 'invalid_cvc', 'cvc'
  end

  it "mocks an expired card error" do
    StripeMock.prepare_card_error(:expired_card)
    expect_card_error 'expired_card', 'exp_month'
  end

  it "mocks an incorrect cvc card error" do
    StripeMock.prepare_card_error(:incorrect_cvc)
    expect_card_error 'incorrect_cvc', 'cvc'
  end

  it "mocks a declined card error" do
    StripeMock.prepare_card_error(:card_declined)
    expect_card_error 'card_declined', nil
  end

  it "mocks a missing card error" do
    StripeMock.prepare_card_error(:missing)
    expect_card_error 'missing', nil
  end

  it "mocks a processing error card error" do
    StripeMock.prepare_card_error(:processing_error)
    expect_card_error 'processing_error', nil
  end

end
