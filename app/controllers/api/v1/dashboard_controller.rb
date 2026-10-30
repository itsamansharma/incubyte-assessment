module Api
  module V1
    class DashboardController < ApplicationController
      def overview
        headcount, payroll_cents, average_cents, median_cents = active_compensation_summary

        render json: {
          headcount: headcount.to_i,
          annual_payroll_usd_cents: payroll_cents.to_i,
          average_annual_salary_usd_cents: average_cents&.round&.to_i,
          median_annual_salary_usd_cents: median_cents&.round&.to_i
        }
      end

      private

      def active_compensation_summary
        Employee.left_joins(:active_compensation)
          .pick(
            Arel.sql("COUNT(employees.id)"),
            Arel.sql("COALESCE(SUM(compensations.amount_usd_cents), 0)"),
            Arel.sql("AVG(compensations.amount_usd_cents)"),
            Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY compensations.amount_usd_cents) FILTER (WHERE compensations.id IS NOT NULL)")
          )
      end
    end
  end
end
