require 'spec_helper'
require 'json'

describe 'Receiver, Unit' do

  clazz = TEF::Keeper::Receiver


  describe 'class level' do
    it_should_behave_like 'a strictly configured component', clazz
  end

  describe 'instance level' do

    before(:each) do
      @mock_logger = create_mock_logger

      @options = {
          in_queue: create_mock_queue,
          out_queue: create_mock_queue,
          callback: double('mock callback'),
          logger: @mock_logger
      }

      @receiver = clazz.new(@options)
    end

    it_should_behave_like 'a logged component, unit level' do
      let(:clazz) { clazz }
      let(:configuration) { @options }
    end


    it 'can be started' do
      expect(@receiver).to respond_to(:start)
    end

    it 'can be stopped' do
      expect(@receiver).to respond_to(:stop)
    end

    describe 'initial setup' do

      it 'will complain if not provided a queue from which to receive tasks' do
        @options.delete(:in_queue)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

      it 'will not complain if not provided a queue to which to post task results' do
        @options.delete(:out_queue)

        expect { clazz.new(@options) }.to_not raise_error
      end

      it 'will complain if not provided a callback with which to handle task results' do
        @options.delete(:callback)

        expect { clazz.new(@options) }.to raise_error(ArgumentError, /must have/i)
      end

    end

    describe 'result handling' do

      before(:each) do
        @fake_task_result = {
            guid: '12345'
        }

        @mock_properties = create_mock_properties
        @fake_in_queue = create_fake_publisher(create_mock_channel)
        @mock_out_queue = create_mock_queue
        @mock_callback = double('callback')
        allow(@mock_callback).to receive(:call)

        @options[:in_queue] = @fake_in_queue
        @options[:out_queue] = @mock_out_queue
        @options[:callback] = @mock_callback

        @receiver = clazz.new(@options)
      end


      it 'uses its callback when handling a result' do
        delivery_info = create_mock_delivery_info
        @receiver.start

        @fake_in_queue.call(delivery_info, @mock_properties, JSON.generate(@fake_task_result))

        expect(@mock_callback).to have_received(:call).with(delivery_info, @mock_properties, @fake_task_result, @mock_logger)
      end

      it 'only uses the callback once when handling a result' do
        @receiver.start

        @fake_in_queue.call(create_mock_delivery_info, @mock_properties, JSON.generate(@fake_task_result))

        expect(@mock_callback).to have_received(:call).exactly(:once)
      end

      it 'will forward tasks if an outbound queue has been set' do
        @options[:out_queue] = @mock_out_queue

        receiver = clazz.new(@options)
        receiver.start

        task_json = JSON.generate(@fake_task_result)
        @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, task_json)

        expect(@mock_out_queue).to have_received(:publish).with(task_json)
      end

      it 'will not forward tasks if there is no outbound queue set' do
        @options[:out_queue] = nil

        receiver = clazz.new(@options)
        receiver.start

        task_json = JSON.generate(@fake_task_result)

        # Since there's nothing to send to, just don't blow up
        expect { @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, task_json) }.to_not raise_error
        expect(@mock_logger).to_not have_received(:warn)
        expect(@mock_logger).to_not have_received(:error)
      end

      describe 'bad result handling' do

        it 'can gracefully handle bad JSON' do
          receiver = clazz.new(@options)
          receiver.start

          bad_request = 'this is not JSON'

          expect { @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, bad_request) }.to_not raise_error
        end

        it 'logs when it receives an invalid result' do
          receiver = clazz.new(@options)
          receiver.start

          bad_request = 'this is not JSON'
          @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, bad_request)

          expect(@mock_logger).to have_received(:error).with(/JSON problem.*#{bad_request}/)
        end

        it 'can gracefully handle callback errors' do
          allow(@mock_callback).to receive(:call).and_raise
          receiver = clazz.new(@options)
          receiver.start

          expect { @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, @fake_task_result.to_json) }.to_not raise_error
        end

        it 'logs when it has a callback error' do
          error = 'Boom!!!'
          allow(@mock_callback).to receive(:call).and_raise(RuntimeError, error)
          receiver = clazz.new(@options)
          receiver.start

          @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, @fake_task_result.to_json)

          expect(@mock_logger).to have_received(:error).with(/Callback error (RuntimeError): #{error}/)
        end

        it 'will not forward a task if a callback error occurs' do
          allow(@mock_callback).to receive(:call).and_raise(RuntimeError)

          receiver = clazz.new(@options)
          receiver.start

          task_json = JSON.generate(@fake_task_result)
          @fake_in_queue.call(create_mock_delivery_info, create_mock_properties, task_json)

          expect(@mock_out_queue).to_not have_received(:publish)
        end

      end

    end

  end
end
