#!/usr/bin/env ruby

require "net/http"
require "uri"

API_BASE_URL = ENV.fetch("API_BASE_URL", "http://127.0.0.1:3000").sub(%r{/+$}, "")
SAMPLE_COUNT = Integer(ENV.fetch("BENCHMARK_SAMPLES", "20"), 10)
WARMUP_COUNT = Integer(ENV.fetch("BENCHMARK_WARMUPS", "3"), 10)

if SAMPLE_COUNT < 1 || WARMUP_COUNT < 0
  abort "BENCHMARK_SAMPLES must be positive and BENCHMARK_WARMUPS cannot be negative"
end

ENDPOINTS = {
  "overview" => "/api/v1/dashboard/overview",
  "breakdown" => "/api/v1/dashboard/breakdown",
  "pay_bands" => "/api/v1/dashboard/pay_bands",
  "employee_page_100" => "/api/v1/employees?page=100&per_page=25",
  "employee_search" => "/api/v1/employees?q=ACM-09999&per_page=25"
}.freeze

def request_time(uri)
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  response = Net::HTTP.get_response(uri)
  elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000
  abort "#{uri}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  [ elapsed_ms, response.body.bytesize ]
end

ENDPOINTS.each do |name, path|
  uri = URI("#{API_BASE_URL}#{path}")
  samples = []
  body_size = 0

  (WARMUP_COUNT + SAMPLE_COUNT).times do |index|
    elapsed_ms, body_size = request_time(uri)
    samples << elapsed_ms if index >= WARMUP_COUNT
  end

  ordered_samples = samples.sort
  p95 = ordered_samples[(0.95 * ordered_samples.length).ceil - 1]
  median = if ordered_samples.length.odd?
    ordered_samples[ordered_samples.length / 2]
  else
    middle = ordered_samples.length / 2
    (ordered_samples[middle - 1] + ordered_samples[middle]) / 2
  end

  puts format("%-20s n=%-3d median=%7.2f ms p95=%7.2f ms body=%d bytes", name, samples.length, median, p95, body_size)
end
