# frozen_string_literal: true

require_relative '../src/main'

RSpec.describe Main do
  let(:client_double) { instance_double(Client) }
  let(:client_response) do
    {
      'id' => 'chatcmpl-123',
      'object' => 'chat.completion',
      'created' => 1_677_652_288,
      'choices' => [{
        'index' => 0,
        'message' => {
          'role' => 'assistant',
          'content' => 'Hello world'
        },
        'finish_reason' => 'stop'
      }],
      'usage' => {
        'prompt_tokens' => 9,
        'completion_tokens' => 12,
        'total_tokens' => 21
      }
    }
  end
  let(:chat_config_double) { instance_double(ChatConfig) }

  before do
    allow(Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:request).and_return(client_response)

    allow(ChatConfig).to receive(:new).and_return(chat_config_double)
    allow(chat_config_double).to receive(:model_profile).and_return('')
    allow(chat_config_double).to receive(:history_messages).and_return([])
    allow(chat_config_double).to receive(:temperature).and_return(1.0)
    allow(chat_config_double).to receive(:configure!).and_return(nil)
  end

  describe 'initialize' do
    it 'does not raise error' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe 'chat!' do
    before do
      allow(Chat)
        .to receive(:read_user_input)
        .and_return({ command_executed: false, histories: [], user_content: 'foobar' })
    end

    it 'does not raise error' do
      main = described_class.new
      expect { main.chat! }.not_to raise_error
    end

    it 'updates history' do
      main = described_class.new
      main.chat!
      expect(main.messages).to eq(
        [{ content: 'foobar', role: 'user' }, { content: 'Hello world', role: 'assistant' }]
      )
    end

    describe 'when error raised' do
      it 'dumps history' do
        allow(Chat).to receive(:read_user_input).and_raise(StandardError)
        allow(Chat).to receive(:dump_message).and_return(nil)

        main = described_class.new
        main.chat!
        expect(Chat).to have_received(:dump_message)
      end
    end
  end
end
