require 'spec_helper'

describe Agents::WebhookAgent do
  let(:agent) do
    _agent = Agents::WebhookAgent.new(:name => 'webhook',
                                      :options => { 'secret' => 'foobar', 'payload_path' => 'some_key' })
    _agent.user = users(:bob)
    _agent.save!
    _agent
  end
  let(:payload) { {'people' => [{ 'name' => 'bob' }, { 'name' => 'jon' }] } }

  describe 'receive_web_request' do
    it 'should create event if secret matches' do
      out = nil
      expect {
        out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
      }.to change { Event.count }.by(1)
      expect(out).to eq(['Event Created', 201])
      expect(Event.last.payload).to eq(payload)
    end

    it 'should be able to create multiple events when given an array' do
      out = nil
      agent.options['payload_path'] = 'some_key.people'
      expect {
        out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
      }.to change { Event.count }.by(2)
      expect(out).to eq(['Event Created', 201])
      expect(Event.last.payload).to eq({ 'name' => 'jon' })
    end

    it 'should not create event if secrets dont match' do
      out = nil
      expect {
        out = agent.receive_web_request({ 'secret' => 'bazbat', 'some_key' => payload }, "post", "text/html")
      }.to change { Event.count }.by(0)
      expect(out).to eq(['Not Authorized', 401])
    end

    describe "receiving events" do

      context "default settings" do

        it "should not accept GET" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "get", "text/html")
          }.to change { Event.count }.by(0)
          expect(out).to eq(['Please use POST requests only', 401])
        end

        it "should accept POST" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

      end

      context "accepting get and post" do

        before { agent.options['verbs'] = 'get;post' }

        it "should accept GET" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "get", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

        it "should accept POST" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

      end

      context "accepting only get" do

        before { agent.options['verbs'] = 'get' }

        it "should accept GET" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "get", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

        it "should not accept POST" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
          }.to change { Event.count }.by(0)
          expect(out).to eq(['Please use GET requests only', 401])
        end

      end

      context "accepting only post" do

        before { agent.options['verbs'] = 'post' }

        it "should not accept GET" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "get", "text/html")
          }.to change { Event.count }.by(0)
          expect(out).to eq(['Please use POST requests only', 401])
        end

        it "should accept POST" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

      end

      context "accepting only put" do

        before { agent.options['verbs'] = 'put' }

        it "should accept PUT" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "put", "text/html")
          }.to change { Event.count }.by(1)
          expect(out).to eq(['Event Created', 201])
        end

        it "should not accept GET" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "get", "text/html")
          }.to change { Event.count }.by(0)
          expect(out).to eq(['Please use PUT requests only', 401])
        end

        it "should not accept POST" do
          out = nil
          expect {
            out = agent.receive_web_request({ 'secret' => 'foobar', 'some_key' => payload }, "post", "text/html")
          }.to change { Event.count }.by(0)
          expect(out).to eq(['Please use PUT requests only', 401])
        end

      end

    end

  end
end
