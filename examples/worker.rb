require 'zeebe_worker'
#require_relative '../lib/zeebe_worker'

class CreateOrderHandler
    def self.run
        puts 'Order created.'
    end
end

class ProcessOrderHandler
    def self.run
        puts 'Order processed.'
    end
end

handlers = {
    create_order: CreateOrderHandler,
    process_order: ProcessOrderHandler
}

ZeebeWorker::Puller.new(handlers).run