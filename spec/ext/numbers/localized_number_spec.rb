require File.join(File.dirname(File.dirname(File.dirname(__FILE__))), "spec_helper")
include TwitterCldr

describe LocalizedNumber do
  before(:each) do
    @number = 10.localize
  end

  describe "#to_decimal" do
    it "should internally create a decimal formatter and return itself" do
      mock.proxy(TwitterCldr::Formatters).const_get(:DecimalFormatter)
      @number.to_decimal.should == @number
    end
  end

  describe "#to_currency" do
    it "should internally create a currency formatter and return itself" do
      mock.proxy(TwitterCldr::Formatters).const_get(:CurrencyFormatter)
      @number.to_currency.should == @number
    end
  end

  describe "#to_percent" do
    it "should internally create a percentage formatter and return itself" do
      mock.proxy(TwitterCldr::Formatters).const_get(:PercentFormatter)
      @number.to_percent.should == @number
    end
  end

  describe "#to_s" do
    it "should default precision to zero for fixnums" do
      mock(@number.formatter).format(@number.base_obj, :precision => 0)
      @number.to_s
    end

    it "should not overwrite precision when explicitly passed" do
      mock(@number.formatter).format(@number.base_obj, :precision => 2)
      @number.to_s(:precision => 2)
    end
  end
end