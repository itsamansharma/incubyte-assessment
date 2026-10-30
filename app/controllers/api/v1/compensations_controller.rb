module Api
  module V1
    class CompensationsController < ApplicationController
      class InvalidCompensationInput < StandardError; end

      MAX_BIGINT = 9_223_372_036_854_775_807

      def create
        employee = find_employee
        attributes, amount_usd_cents = validated_compensation
        compensation = nil

        employee.with_lock do
          employee.active_compensation&.update!(is_active: false)
          compensation = employee.compensations.create!(
            amount_cents: attributes.fetch(:amount_cents),
            currency: attributes.fetch(:currency),
            amount_usd_cents: amount_usd_cents,
            effective_date: attributes.fetch(:effective_date),
            change_reason: attributes.fetch(:change_reason),
            is_active: true
          )
        end

        render json: {
          employee_id: employee.id,
          compensation: serialize_compensation(compensation)
        }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Employee not found" }, status: :not_found
      rescue ActionController::ParameterMissing, InvalidCompensationInput => error
        render json: { error: error.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def find_employee
        employee_id = params[:employee_id].to_s
        raise ActiveRecord::RecordNotFound unless employee_id.match?(/\A\d+\z/)

        Employee.find(employee_id)
      end

      def validated_compensation
        input = params.require(:compensation).permit(
          :amount_cents,
          :currency,
          :effective_date,
          :change_reason
        )
        amount_cents = input[:amount_cents].to_s
        unless amount_cents.match?(/\A\d+\z/)
          raise InvalidCompensationInput, "amount_cents must be a non-negative integer"
        end

        currency = input[:currency].to_s.upcase
        unless currency.match?(/\A[A-Z]{3}\z/)
          raise InvalidCompensationInput, "currency must be a three-letter code"
        end

        rate = ExchangeRate.find_by(currency_code: currency)
        raise InvalidCompensationInput, "unsupported currency" unless rate

        effective_date = begin
          Date.iso8601(input[:effective_date].to_s)
        rescue Date::Error
          raise InvalidCompensationInput, "effective_date must use YYYY-MM-DD format"
        end

        change_reason = input[:change_reason].to_s.strip
        if change_reason.blank? || change_reason.length > 100
          raise InvalidCompensationInput, "change_reason must be between 1 and 100 characters"
        end

        attributes = {
          amount_cents: amount_cents.to_i,
          currency: currency,
          effective_date: effective_date,
          change_reason: change_reason
        }
        amount_usd_cents = (BigDecimal(amount_cents) * rate.rate_to_usd)
          .round(0, BigDecimal::ROUND_HALF_UP)
          .to_i
        if amount_cents.to_i > MAX_BIGINT || amount_usd_cents > MAX_BIGINT
          raise InvalidCompensationInput, "salary exceeds the supported amount"
        end

        [ attributes, amount_usd_cents ]
      end

      def serialize_compensation(compensation)
        {
          id: compensation.id,
          amount_cents: compensation.amount_cents,
          currency: compensation.currency,
          amount_usd_cents: compensation.amount_usd_cents,
          effective_date: compensation.effective_date,
          change_reason: compensation.change_reason,
          is_active: compensation.is_active
        }
      end
    end
  end
end
