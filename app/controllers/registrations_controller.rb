class RegistrationsController < Devise::RegistrationsController

  def create
    build_resource(sign_up_params)

    resource.class.transaction do
      resource.save
      yield resource if block_given?
      if resource.persisted?
        begin
          @payment = Payment.new({
                                   email: params["user"]["email"],
                                   token: token_params,
                                   user_id: resource.id })
          @payment.process_payment
          @payment.save
        rescue Exception => e
          flash[:alert] = e.message
          puts e.message
          resource.destroy
          puts "Payment failed"
          render :'devise/registrations/new' and return
        end

        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).push(:payment)
  end

  def token_params
    token_payment(params[:payment][:card_number], params[:payment][:card_expires_month], params[:payment][:card_expires_year], params[:payment][:card_cvc]).id
  end

  def token_payment(card_number, exp_month, exp_year, cvc)
    Stripe::Token.create({
                           card:{
                             number: card_number,
                             exp_month: exp_month,
                             exp_year: exp_year,
                             cvc: cvc
                           }
                         })
  end

end