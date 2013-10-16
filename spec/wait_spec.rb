require "rspec"
require_relative "./support/wait"

describe WaitHelper do
  it "calls the block the given number of times" do
    calls = 0
    blk = Proc.new do
      calls += 1
      raise "Hi from blk"
    end

    expect {
      wait(3, &blk)
    }.to raise_error("Hi from blk")

    expect(calls).to eq(3)
  end
end