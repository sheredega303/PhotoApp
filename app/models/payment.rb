class Payment < ApplicationRecord
  attr_accessor :card_number, :card_cvc, :card_expires_month, :card_expires_year, :plan
  belongs_to :user

  def self.month_options
    Date::MONTHNAMES.compact.each_with_index.map { |name, i| ["#{i+1} - #{name}", i+1]}
  end

  def self.year_options
    (Date.today.year..(Date.today.year+10)).to_a
  end

  def process_payment
    customer = create_customer(email, token)
    Stripe::Charge.create({
                            amount: price,
                            currency: "usd",
                            source: customer.default_source,
                            customer: customer.id,
                            description: description
                          })
  end

  def create_customer(email, token)
    Stripe::Customer.create({
                              email: email,
                              source: token
                            })
  end

  def price
    if :plan == "Premium Plan"
      return 1000
    end
    2000
  end

  def description
    if :plan == "Premium Plan"
      return "Premium Plan on PhotoApp SignUp"
    end
    "Amaze Plan on PhotoApp SignUp"
  end

end
