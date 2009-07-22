require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rexml/document'
require 'net/http'
require 'pp'


module Atnd4r
  # private methods to public
  public_class_method :get_xml, :parse_users_xml, :parse_events_xml, :parse_common_xml, :make_query
end

describe Atnd4r, "get_event_list で値を取得した場合" do
  xml_string =<<-EOF
<hash>
  <results-returned type="integer">9999</results-returned>
  <results-available type="integer">1</results-available>
  <events type="array">
    <event>
      <accepted type="integer">1</accepted>
      <event-id type="integer">1</event-id>
      <updated-at type="datetime">2009-01-01T00:00:00+09:00</updated-at>
      <title>hoge event</title>
      <waiting type="integer">0</waiting>
      <event-url>hoge.com</event-url>
      <users type="array">
        <user>
          <status type="integer">1</status>
          <nickname>name</nickname>
          <user-id type="integer">1</user-id>
        </user>
      </users>
      <limit type="integer">1</limit>
    </event>
  </events>
  <results-start type="integer">1</results-start>
</hash>
  EOF
  before(:each) do
    @http_mock = create_http_mock(xml_string, "200", "200 Ok")
    Net::HTTP.stub!(:start).and_yield(@http_mock)
  end
  
  it "AtndAPI オブジェクトが取得されること" do
    event = Atnd4r::get_event_list({:event_id => 1})
    event.class.should == Atnd4r::AtndAPI
    event.results_returned.should == 9999
    event.events[0].title.should == "hoge event"
    event.events[0].users[0].nickname.should == "name"
  end

  after do
    @http_mock = nil
  end
end

describe Atnd4r, "get_user_list で値を取得した場合" do
  xml_string =<<-EOF
<hash>
  <results-returned type="integer">9999</results-returned>
  <results-available type="integer">1</results-available>
  <events type="array">
    <event>
      <accepted type="integer">1</accepted>
      <event-id type="integer">1</event-id>
      <updated-at type="datetime">2009-01-01T00:00:00+09:00</updated-at>
      <title>hoge event</title>
      <waiting type="integer">0</waiting>
      <event-url>hoge.com</event-url>
      <users type="array">
        <user>
          <status type="integer">1</status>
          <nickname>name</nickname>
          <user-id type="integer">1</user-id>
        </user>
      </users>
      <limit type="integer">1</limit>
    </event>
  </events>
  <results-start type="integer">1</results-start>
</hash>
  EOF
  before(:each) do
    @http_mock = create_http_mock(xml_string, "200", "200 Ok")
    Net::HTTP.stub!(:start).and_yield(@http_mock)
  end
  
  it "AtndAPI オブジェクトが取得されること" do
    event = Atnd4r::get_user_list({:user_id => 1})
    event.class.should == Atnd4r::AtndAPI
    event.results_returned.should == 9999
    event.events[0].title.should == "hoge event"
    event.events[0].users[0].nickname.should == "name"
  end

  after do
    @http_mock = nil
  end
end

describe "Atnd4r::get_xml で、サーバーエラー(4xx)が返された)場合" do
  before(:each) do
    @http_mock = create_http_mock("body", "400", "400_error")
    Net::HTTP.stub!(:start).and_yield(@http_mock)
  end

  it "は、400 ならATNDHTTPError を返す事" do
    lambda {
      Atnd4r.get_xml("api", "query")
    }.should raise_error(Atnd4r::ATNDHTTPError, /400_error/)
  end

  after do
    @http_mock = nil
  end
end

describe "Atnd4r::get_xml で、サーバーエラー(4xx)が返された)場合" do
  before(:each) do
    @http_mock = create_http_mock("body", "500", "500_error")
    Net::HTTP.stub!(:start).and_yield(@http_mock)
  end

  it "は、500 ならATNDHTTPError を返す事" do
    lambda {
      Atnd4r.get_xml("api", "query")
    }.should raise_error(Atnd4r::ATNDHTTPError, /500_error/)
  end

  after do
    @http_mock = nil
  end
end

describe "Atnd4r::get_xml でXML が正しく取得できたとき" do
  before(:each) do
    xml_string = "<tag>hoge</tag>"
    @http_mock = create_http_mock(xml_string, "200", "200 Ok")
    Net::HTTP.stub!(:start).and_yield(@http_mock)
  end

  it "は、XMLオブジェクトの値として、 hoge を返す事" do
    doc = Atnd4r.get_xml("api", "query")
    doc.elements["tag"].text.should == "hoge"
  end

  after do
    @http_mock = nil
  end
end


describe "Atnd4r::make_query が、引数なしのパラメータを解析するとき" do
  it "は、文字列を返す事" do
    query = Atnd4r::make_query()
    query.class.should == String
  end

  it "は、内容は空文字列になっていること" do
    query = Atnd4r::make_query()
    query.should == ""
  end
end

describe "Atnd4r::make_query がひとつのkey&valueのパラメータを解析するとき" do
  it "は、Keyがシンボルでも文字列を返す事" do
    query = Atnd4r::make_query({:key => "value"})
    query.should == "key=value"
  end

  it "は、Keyが文字列でも文字列を返す事" do
    query = Atnd4r::make_query({"key" => "value"})
    query.should == "key=value"
  end

  it "は、Keyやvalueにスペースが混じっている場合除去された文字列を返す事" do
    query = Atnd4r::make_query({"  key " => " value "})
    query.should == "key=value"
  end
end

describe "Atnd4r::make_query がひとつのkey 対して複数valueのパラメータを解析するとき" do
  it "は、値が複数の場合は、カンマ区切りになるよ" do
    query = Atnd4r::make_query({"key" => ["value1", "value2"]})
    query.should == "key=value1,value2"
  end
end

describe "Atnd4r::make_query がひとつのkey 対してvalueが nil のとき" do
  it "は、値が空文字になるよ" do
    query = Atnd4r::make_query({"key" => nil})
    query.should == "key="
  end
end

describe "Atnd4r::parse_users_xml XML がエラーメッセージだったとき" do
  xml_string = "<hash><error><message>error!</message></error></hash>"
  doc = REXML::Document.new xml_string

  it "は、例外 ATNDParameterError が発生する" do 
    lambda {
      Atnd4r.parse_users_xml(doc)
    }.should raise_error(Atnd4r::ATNDParameterError, /error!/)
  end
end

describe "Atnd4r::parse_common_xml が正常に処理したとき" do
  xml_string =<<-EOF
  <hash>
    <results-returned type="integer">1</results-returned>
    <results-available type="integer">2</results-available>
    <results-start type="integer">3</results-start>
  </hash>
  EOF
  doc = REXML::Document.new xml_string

  events = Atnd4r::parse_common_xml(doc)
  it "は、AtndAPIオブジェクトの内容として、result_xxx の値を持っている事" do
    events.results_returned.should == 1
    events.results_available.should == 2
    events.results_start.should == 3
  end
end


describe "Atnd4r::parse_users_xml が正常に処理したとき" do
  xml_string =<<-EOF
<hash>
  <results-returned type="integer">1</results-returned>
  <results-available type="integer">1</results-available>
  <events type="array">
    <event>
      <accepted type="integer">1</accepted>
      <event-id type="integer">1</event-id>
      <updated-at type="datetime">2009-01-01T00:00:00+09:00</updated-at>
      <title>hoge event</title>
      <waiting type="integer">0</waiting>
      <event-url>hoge.com</event-url>
      <users type="array">
        <user>
          <status type="integer">1</status>
          <nickname>name</nickname>
          <user-id type="integer">1</user-id>
        </user>
      </users>
      <limit type="integer">1</limit>
    </event>
  </events>
  <results-start type="integer">1</results-start>
</hash>
  EOF
  doc = REXML::Document.new xml_string

  it "は、入力されたイベントの値がそのまま取得できる" do 
    events = Atnd4r.parse_users_xml(doc)
    events.length.should == 1
    events[0].accepted.should == 1
    events[0].event_id.should == 1
    events[0].updated_at.should == Date.parse("2009-01-01T00:00:00+09:00")
    events[0].title.should == "hoge event"
    events[0].waiting.should == 0
    events[0].event_url.should == "hoge.com"
    events[0].limit.should == 1
  end

  it "は、入力されたユーザの値がそのまま取得できる" do 
    events = Atnd4r.parse_users_xml(doc)
    events[0].users.length.should == 1
    events[0].users[0].status.should == 1
    events[0].users[0].nickname.should == "name"
    events[0].users[0].user_id.should == 1
  end
end


describe "Atnd4r::parse_events_xml が正常に処理したとき" do
  xml_string =<<-EOF
<hash>
  <results-returned type="integer">1</results-returned>
  <results-available type="integer">1</results-available>
  <events type="array">
    <event>
      <place/>
      <lon type="decimal">0.0</lon>
      <accepted type="integer">1</accepted>
      <event-id type="integer">1</event-id>
      <updated-at type="datetime">2009-01-01T00:00:00+09:00</updated-at>
      <title>hoge event</title>
      <ended-at nil="true"/>
      <waiting type="integer">0</waiting>
      <event-url>hoge.com</event-url>
      <url nil="true"/>
      <owner-nickname>name</owner-nickname>
      <catch>catch</catch>
      <description>description</description>
      <owner-id type="integer">1</owner-id>
      <limit type="integer">1</limit>
      <lat nil="true"/>
      <address/>
      <started-at type="datetime">2009-01-01T00:00:00+09:00</started-at>
    </event>
  </events>
  <results-start type="integer">1</results-start>
</hash>
  EOF
  doc = REXML::Document.new xml_string

  it "は、入力されたイベントの値がそのまま取得できる" do 
    events = Atnd4r.parse_events_xml(doc)
    events.length.should == 1
    events[0].lon.should == 0.0
    events[0].accepted.should == 1
    events[0].event_id.should == 1
    events[0].updated_at.should == Date.parse("2009-01-01T00:00:00+09:00")
    events[0].started_at.should == Date.parse("2009-01-01T00:00:00+09:00")
    events[0].title.should == "hoge event"
    events[0].waiting.should == 0
    events[0].event_url.should == "hoge.com"
    events[0].url.should == nil
    events[0].owner_nickname.should == "name"
    events[0].owner_id.should == 1
    events[0].description.should == "description"
    events[0].catch.should == "catch"
    events[0].lat.should == nil
    events[0].address.should == nil
    events[0].limit.should == 1
  end

end


