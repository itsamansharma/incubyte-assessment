module Api
  module V1
    class CompensationSerializer
      def self.as_json(compensation)
        return unless compensation

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
