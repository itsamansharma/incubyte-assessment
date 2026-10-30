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

      def breakdown
        render json: {
          departments: grouped_summary(Employee.joins(:department), "departments.name", :department),
          countries: grouped_summary(Employee.all, "employees.country_code", :country_code)
        }
      end

      def pay_bands
        groups = Employee.joins(:department, :active_compensation)
          .group("departments.name", "employees.job_level")
          .order("departments.name", "employees.job_level")
          .pluck(
            Arel.sql("departments.name"),
            Arel.sql("employees.job_level"),
            Arel.sql("COUNT(employees.id)"),
            Arel.sql("PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY compensations.amount_usd_cents)"),
            Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY compensations.amount_usd_cents)"),
            Arel.sql("PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY compensations.amount_usd_cents)")
          )

        render json: {
          groups: groups.map do |department, job_level, headcount, p25_cents, median_cents, p75_cents|
            {
              department: department,
              job_level: job_level,
              headcount: headcount.to_i,
              p25_annual_salary_usd_cents: p25_cents.round.to_i,
              median_annual_salary_usd_cents: median_cents.round.to_i,
              p75_annual_salary_usd_cents: p75_cents.round.to_i
            }
          end
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

      def grouped_summary(employees, group_column, label_key)
        employees
          .left_joins(:active_compensation)
          .group(Arel.sql(group_column))
          .order(Arel.sql(group_column))
          .pluck(
            Arel.sql(group_column),
            Arel.sql("COUNT(employees.id)"),
            Arel.sql("COALESCE(SUM(compensations.amount_usd_cents), 0)"),
            Arel.sql("AVG(compensations.amount_usd_cents)"),
            Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY compensations.amount_usd_cents) FILTER (WHERE compensations.id IS NOT NULL)")
          )
          .map do |label, headcount, payroll_cents, average_cents, median_cents|
            {
              label_key => label,
              headcount: headcount.to_i,
              annual_payroll_usd_cents: payroll_cents.to_i,
              average_annual_salary_usd_cents: average_cents&.round&.to_i,
              median_annual_salary_usd_cents: median_cents&.round&.to_i
            }
          end
      end
    end
  end
end
