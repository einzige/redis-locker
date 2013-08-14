require 'spec_helper'


describe RedisLocker do
  let(:queue_name) { 'queue_name' }
  subject { described_class.new(queue_name, 6) }

  describe "#initialize" do
    it 'assigns key' do
      subject.key.should == queue_name
    end

    it 'assigns time_limit' do
      subject.time_limit.should == 6
    end
  end

  describe "#enter_queue" do
    context "calling multiple times" do
      before { subject.enter_queue }
      its(:running?) { should be_true }
      it { expect { subject.enter_queue }.to raise_error("This block is already in the queue") }

      context "after exit" do
        before { subject.exit_queue }
        its(:running?) { should be_false }
        it { expect { subject.enter_queue }.not_to raise_error }
      end
    end
  end

  describe "#ready?" do
    its(:ready?) { should be_true }

    context "trash in a queue" do
      before do
        described_class.redis.lpush queue_name, 'whatever'
      end

      its(:current?) { should be_false }
      its(:ready?) { should be_true }
    end

    context "pending timestamp in a queue" do
      before do
        subject.enter_queue
      end

      its(:current?) { should be_true }

      context "stale" do
        before do
          described_class.redis.lpush queue_name, subject.timestamp.to_f + 10000
        end

        its(:current?) { should be_false }
        its(:ready?) { should be_true }
      end

      context "not stale" do
        context "same time" do
          before do
            described_class.redis.lpush queue_name, subject.timestamp.to_f
          end

          its(:current?) { should be_true }
          its(:ready?) { should be_true }
        end

        context "later time" do
          context "same time" do
            before do
              described_class.redis.lpush queue_name, subject.timestamp.to_f + 0.00001
            end

            its(:current?) { should be_false }
            its(:ready?) { should be_true }
          end
        end
      end
    end

    context "concurrent threads" do
      let(:concurrent_locker_1) { described_class.new(queue_name) }
      let(:concurrent_locker_2) { described_class.new(queue_name) }
      let(:unrelated_locker) { described_class.new('unrelated') }

      before do
        concurrent_locker_1.enter_queue
        concurrent_locker_2.enter_queue
        unrelated_locker.enter_queue
      end

      it 'allows first locker in the queue to be run' do
        concurrent_locker_1.ready?.should be_true
      end

      it 'makes second locker in the queue wait' do
        concurrent_locker_2.ready?.should be_false
      end

      it 'does not have an impact on a separate queue' do
        unrelated_locker.ready?.should be_true
      end
    end
  end

  describe "#run" do
    context "with breaking block" do
      before do
        subject.should_receive(:exit_queue).once
      end

      it 'exits queue even if something fails' do
        expect { subject.run { raise 'PIZDEC!' } }.to raise_error('PIZDEC!')
      end
    end

    describe "locking", integrational: true do
      it 'locks' do
        looser = nil
        winner = nil

        concurrent_request = proc do |id|
          proc do
            described_class.new(queue_name).run do
              looser = id

              if winner
                winner.should_not == looser
              else
                winner = id
                sleep(5)
              end
            end
          end
        end

        thr_1 = Thread.new &concurrent_request.call(1)
        thr_2 = Thread.new &concurrent_request.call(2)

        thr_1.join
        thr_2.join
      end
    end
  end

  describe "#run!" do
    context "reaching deadline" do
      before do
        subject.should_receive(:clear_queue)
      end
      it { expect { subject.run!(0.0000000001, true) { sleep(0.00001) } }.to raise_error(Timeout::Error) }
    end
  end
end