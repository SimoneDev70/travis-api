require 'libhoney'

module Travis
  class Honeycomb
    class << self
      # env vars used to configure rpc client:
      # * HONEYCOMB_RPC_ENABLED_FOR_DYNOS
      # * HONEYCOMB_RPC_WRITEKEY
      # * HONEYCOMB_RPC_DATASET
      # * HONEYCOMB_RPC_SAMPLE_RATE
      def rpc
        @rpc ||= Client.new('HONEYCOMB_RPC_')
      end

      def rpc_setup
        return unless rpc.enabled?

        Travis.logger.info 'honeycomb rpc enabled'

        ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          event = payload.merge(
            event: name,
            duration_ms: ((finish - start) * 1000).to_i,
            id: id,
          )

          rpc.send(event)
        end
      end
    end

    class Client
      def initialize(prefix = 'HONEYCOMB_')
        @prefix = prefix
      end

      def send(event)
        return unless enabled?

        ev = honey.event
        ev.add(event)
        ev.send
      end

      def enabled?
        @enabled ||= env('ENABLED_FOR_DYNOS')&.split(' ')&.include?(ENV['DYNO'])
      end

      private

        def honey
          @honey ||= Libhoney::Client.new(
            writekey: env('WRITEKEY'),
            dataset: env('DATASET'),
            sample_rate: env('SAMPLE_RATE')&.to_i || 1
          )
        end

        def env(name)
          ENV[@prefix + name]
        end
    end
  end
end
