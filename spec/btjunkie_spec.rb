require "spec_helper"

describe Btjunkie do
  before(:each) do
    @cookies = {
      :sessid => "6b9d6fac8b5c66756b4f532c175748c8"
    }
  end
  
  describe "#page" do
    it "should be possible pass a page" do
      Btjunkie.page(10).should be_instance_of(Btjunkie)
    end
  end
  
  describe "#cookies" do
    it "should be possible pass a page" do
      Btjunkie.cookies({
        :random => "random"
      }).should be_instance_of(Btjunkie)
    end
  end
  
  describe "errors" do
    it "should raise an error if no category if being defined" do      
      lambda { 
        Btjunkie.results
      }.should raise_error(ArgumentError, "You need to specify a category")
    end
    
    it "should raise an error if no cookies if being passed" do
      lambda { 
        Btjunkie.category(:movies).results 
      }.should raise_error(ArgumentError, "You need to specify a cookie using #cookies")
    end
  end
  
  describe "#results" do
    describe "movies category" do
      use_vcr_cassette "movies"
      before(:each) do
        @bt = Btjunkie.category(:movies).cookies(@cookies)
      end
      
      it "should return a list of 40 torrents" do
        @bt.should have_at_least(40).results
      end
      
      it "should contain the right data" do
        object = mock(Object.new)
        object.should_receive(:based_on).at_least(40).times
        
        @bt.results.each do |torrent|
          torrent.torrent.should match(URI.regexp)
          torrent.torrent.should match(/\.torrent$/)
          torrent.torrent.should match(/^http:\/\//)
          torrent.title.should_not be_empty
          torrent.details.should match(URI.regexp)
          torrent.should_not be_dead
          torrent.seeders.should be_instance_of(Fixnum)
          torrent.should be_instance_of(BtjunkieContainer::Torrent)
          torrent.domain.should eq("btjunkie.org")
          torrent.id.should match(/[a-z0-9]+/)
          torrent.tid.should match(/[a-fA-F\d]{32}/)
          torrent.torrent_id.should eq(torrent.id)
          torrent.should be_valid
          MovieSearcher.should_receive(:find_by_release_name).with(torrent.title, :options => {
            :details => true
          }).and_return(Struct.new(:imdb_id).new("123"))
                    
          Undertexter.should_receive(:find).with("123", :language => :english).and_return(object)
            
          torrent.subtitle(:english)
        end
      end
    end
    
    describe "empty request" do
      before(:each) do
        stub_request(:get, "http://btjunkie.org/browse/Video?o=72&p=10&s=1&t=1").to_return(:body => "")
      end
      
      it "should no raise an error" do
        lambda { 
          Btjunkie.category(:movies).cookies(@cookies).page(10).results
        }.should_not raise_error
      end
      
      it "should not contain any torrents" do
        Btjunkie.category(:movies).cookies(@cookies).page(10).results.count.should be_zero
      end
    end
  end
  
  describe "bugs" do
    describe "bug 1" do
      use_vcr_cassette "bug1"
      
      before(:each) do
        @bt = Btjunkie.category(:movies).cookies(@cookies)
        @bt.should_receive(:url).and_return("http://btjunkie.org/search?q=Limitless-2011-TS-XviD-IMAGiNE-torrentzilla-org")
      end
      
      it "should not raise an error calling the Btjunkie#tid method" do
        lambda { 
          @bt.results.first.tid
        }.should_not raise_error
      end
      
      it "should not be valid" do
        @bt.results.each do |torrent|
          torrent.should_not be_valid
        end
      end
    end
  end
  
  describe "#find_by_details" do
    before(:each) do
      @url = "http://btjunkie.org/torrent/Pirates-of-the-Caribbean-4-2011-XViD-MEM-ENG-AUDIO/3952ef0859f08bbc7b63c97c51bd9a02e154e0c38026"
    end
    
    describe "correct data" do
      use_vcr_cassette "find_by_details"
      
      before(:each) do
        @torrent = Btjunkie.cookies(@cookies).find_by_details(@url)
      end
      
      it "should have a torrent url" do
        @torrent.torrent.should eq("http://dl.btjunkie.org/torrent/Pirates-of-the-Caribbean-4-2011-XViD-MEM-ENG-AUDIO/3952ef0859f08bbc7b63c97c51bd9a02e154e0c38026/download.torrent")
      end

      it "should have some seeders" do
        @torrent.seeders.should eq(62152)
      end

      it "should have some seeders" do
        @torrent.details.should eq(@url)
      end

      it "should have a title" do
        @torrent.title.should eq("Pirates of the Caribbean 4 2011 XViD- MEM [ENG AUDIO]")
      end

      it "should be valid" do
        @torrent.should be_valid
      end
    end
    
    describe "no data" do
      before(:each) do
        stub_request(:get, @url).to_return(:body => "")
      end

      it "should not raise an error if btjunkie.org returns strange data" do
        torrent = Btjunkie.cookies(@cookies).find_by_details(@url)
        lambda { 
          ["torrent", "seeders", "details", "title"].each do |method|
            torrent.send(method)
          end
        }.should_not raise_error
      end
      
      it "should not be valid" do
        Btjunkie.cookies(@cookies).find_by_details(@url).should_not be_valid
      end
    end
  end
end