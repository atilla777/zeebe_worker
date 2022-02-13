# frozen_string_literal: true

require 'zeebe/client'
require 'uri'

module ZeebeWorker
    # TODO: fix grammar errors
    # Puller continusly fetch tasks from zeebe and run apropriate ruby code (handlers) to make them complite
    class Puller
        class MissingHandlersHash < ArgumentError; end
        class UnknownJobError < StandardError; end

        ZEEBE_HOST = ENV['ZEEBE_HOST'] || 'localhost'
        ZEEBE_PORT = ENV['ZEEBE_PORt'] || 26500
        ZEEBE_MAX_JOBS_PER_REQUEST = ENV['ZEEBE_MAX_JOBS_PER_REQUEST'] || 1
        # TODO correct name (what timeout do?)
        ZEEBE_TIMEOUT = ENV['ZEEBE_MAX_JOBS_PER_REQUEST'] || 10
        WORKER_NAME = ENV['ZEEBE_WORKER_NAME'] || 'ruby_zeebe_worker'

        private

        attr_reader :connection, :handlers, :task_types, :worker_name, :requests

        public 

        # config is a hash where:
        # - keys is zeebe task Type attribute
        # - values is ruby class that handle task type
        # Example:
        # {
        #   create_order: CreateOrderHandler,
        #   cancel_order: CancelOrderHandler
        # }
        def initialize(handlers, worker_name = WORKER_NAME)
            raise MissingHandlersHash.new("Config should be a hash") unless handlers.is_a?(Hash)

            @task_types = handlers.keys.map { |type| type.to_s }
            @connection = Zeebe::Client::GatewayProtocol::Gateway::Stub.new(
                zeebe_uri.to_s, :this_channel_is_insecure
            )

            print_zeebe_info

            @worker_name = worker_name
            @handlers = handlers
            # TODO: move request to class
            @requests = prepare_requests
        end

        def run
            loop do
                # TODO: make requests in parralel (fibers, ractors?)
                requests.each { |request| run_request(request) }
                # TODO: replace by log
                puts "Pull by #{worker_name} finished"
            end
        end

        private

        def prepare_requests
            task_types.each_with_object([]) do |task_type, tasks|
                tasks << Zeebe::Client::GatewayProtocol::ActivateJobsRequest.new(
                    type: task_type,
                    worker: worker_name,
                    maxJobsToActivate: ZEEBE_MAX_JOBS_PER_REQUEST,
                    timeout: ZEEBE_TIMEOUT
                )
            end
        end

        # Take task of given type from zeebe and make aproppriate job
        def run_request(request)
            response = connection.activate_jobs(request).first
            handle_response(response) if response.is_a?(Zeebe::Client::GatewayProtocol::ActivateJobsResponse)
        end

        def zeebe_uri
           URI("#{ZEEBE_HOST}:#{ZEEBE_PORT}") 
        end

        def print_zeebe_info
            topology = connection.topology(Zeebe::Client::GatewayProtocol::TopologyRequest.new)

            puts "Zeebe topology:"
            puts "  Cluster size: #{topology.clusterSize}"
            puts "  Replication factor: #{topology.replicationFactor}"
            puts "  Brokers:"

            topology.brokers.each do |b|
            puts "    - id: #{b.nodeId}, address: #{b.host}:#{b.port}, partitions: #{b.partitions.map { |p| p.partitionId }}"
            end
        end

        def handle_response(response)
            response.jobs.each do |job|
                # TODO: run jobs in paralel (fibers, ractors?)
                raise UnknownJobError.new("Fetched from zeebe job type (#{job.type}) is unknown") unless task_types.include?(job.type)
                # TODO: add job params to arguments
                handlers[job.type.to_sym].run
                complete_job(job.key)
            end
        end

        def complete_job(job_key)
            connection.complete_job(
                Zeebe::Client::GatewayProtocol::CompleteJobRequest.new(jobKey: job_key)
            )
        end
    end
end