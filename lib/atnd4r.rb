require 'net/http'
require 'rexml/document'

module Atnd4r
  @atnd_api_url = 'api.atnd.org'
  @atnd_api_port = 80
  @atnd_api_events = '/events/'
  @atnd_api_users = '/events/users/'

  # ATND へのリクエストで 400 番台や 500 番台の応答コードが返された時に出力されます
  class ATNDHTTPError < StandardError; end

  # ATND へのリクエスト時のパラメータが不正（もしくは何も無かった場合）
  class ATNDParameterError < StandardError; end;

  ########################
  # アクセッサメソッド
  ########################

  #ATND の HOST名（http:// は不要）を設定します。
  #万が一 URL に変更がある場合は独自に設定してください
  def self.atnd_api_url=(val = "")
    @atnd_api_url = val
  end
  
  #ATND の ポート番号を設定します。
  #万が一 URL に変更がある場合は独自に設定してください
  def self.atnd_api_port=(val = 0)
    @atnd_api_port = val.to_i
  end

  #ATND の イベント情報 API のパスを設定します。(末尾は '/' である必要があります)
  #万が一 URL に変更がある場合は独自に設定してください
  def self.atnd_api_events=(val = 0)
    @atnd_api_events = val.to_i
  end

  #ATND の 出席情報 API のパスを設定します。(末尾は '/' である必要があります)
  #万が一 URL に変更がある場合は独自に設定してください
  def self.atnd_api_users=(val = "")
    @atnd_api_users = val
  end

  ###################
  # public method
  ##################

  #== イベントサーチAPI
  #イベントサーチAPI を実行します
  #=== 引数
  #_param_:: Hashのオブジェクト。一つの検索パラメータに対して、複数の値を渡す場合は、value部分を配列にしてください。
  #例えば、event_id で検索する場合は、下記のようなパラメータを渡してください
  #  {:event_id => 1}
  #event_id を複数渡したい場合は配列にします。
  # {:event_id => [1,2]}
  #=== 戻り値
  #Atnd4r::AtndAPI:: Atnd4r::AtndAPIオブジェクト
  #=== 例外 
  #Atnd4r::ATNDHTTPError:: API ヘアクセスした際に、400系や500系の応答コードがかえってきた場合に発生します
  #Atnd4r::ATNDParameterError:: API 実行結果に Error メッセージが入っていた場合に発生します
  def self.get_event_list(param = {})
    xml = get_xml(@atnd_api_events, make_query(param))
    event = parse_common_xml(xml)
    event.events = parse_events_xml(xml)

    return event
  end

  #== 出欠確認API
  #出欠確認API を実行します
  #=== 引数
  #_param_:: Hashのオブジェクト。一つの検索パラメータに対して、複数の値を渡す場合は、value部分を配列にしてください。
  #例えば、user_id で検索する場合は、下記のようなパラメータを渡してください
  #  {:user_id => 1}
  #user_id を複数渡したい場合は配列にします。
  # {:user_id => [1,2]}
  #=== 戻り値
  #Atnd4r::AtndAPI:: Atnd4r::AtndAPIオブジェクト
  #=== 例外 
  #Atnd4r::ATNDHTTPError:: API ヘアクセスした際に、400系や500系の応答コードがかえってきた場合に発生します
  #Atnd4r::ATNDParameterError:: API 実行結果に Error メッセージが入っていた場合に発生します
  def self.get_user_list(param = {})
    xml = get_xml(@atnd_api_users, make_query(param))
    event = parse_common_xml(xml)
    event.events = parse_users_xml(xml)

    return event
  end

  ###################
  # private method
  ##################
  
  # パラメータから QueryString を作成する。一つの Key に複数の値がある場合、カンマ区切りにする
  def self.make_query(param = {})
    query = []
    param.each do |key, val|
      if val.nil?
        val = ""
      end

      # format のオプションは無視する（XML固定のため）
      if key.to_s == 'format'
        next
      end
      # key がシンボルの場合に備えて to_s しておく
      query << key.to_s.strip + "=" +  Array(val).map {|value| value.to_s.strip}.join(",")
    end

    # format を XML にする
    query << 'format=xml'

    return query.join("&")
  end
  
  # 共通の XMLデータのパース
  def self.parse_common_xml(xml)
    common = AtndAPI.new(xml.elements['hash'])
  end

  # AtndEvent の配列を返却する
  def self.parse_events_xml(xml)
    events_list = [] # AtndEvent の配列
    
    # /hash/error/message があったら Error とする
    raise ATNDParameterError.new("ATND Request Parameter Error : " + xml.elements['/hash/error/message'].text) if xml.elements['/hash/error/message']

    xml.elements.each('/hash/events/event') do |event|
      events_list << AtndEvent.new(event)
    end

    return events_list
  end
  

  # AtndEvent の配列を返却する
  def self.parse_users_xml(xml)
    users_list = [] # AtndEvent の配列
    
    # /hash/error/message があったら Error とする
    raise ATNDParameterError.new("ATND Request Parameter Error : " + xml.elements['/hash/error/message'].text) if xml.elements['/hash/error/message']

    xml.elements.each('/hash/events/event') do |event|
      users_list << AtndEvent.new(event)
    end 

    return users_list
  end

  # ATND API を実行して、XML を取得する
  def self.get_xml(api_url, query)
    doc = nil
    Net::HTTP.version_1_2
    Net::HTTP.start(@atnd_api_url, @atnd_api_port) do |http|
      response = http.get(api_url + '?' + query)
      if response.code =~ /[45]\d\d/
        raise ATNDHTTPError.new("ATND API Server Error : #{response['status']}")
      end
      doc = REXML::Document.new response.body
    end
    return doc
  end

  ################
  # private setting
  ###############
  private_class_method :get_xml, :parse_common_xml, :parse_events_xml, :parse_users_xml, :make_query

  class AtndAPI
    def initialize(xml)
      @results_returned  = AtndAPIUtil::to_ruby_type xml.elements['results-returned']
      @results_available = AtndAPIUtil::to_ruby_type xml.elements['results-available']
      @results_start     = AtndAPIUtil::to_ruby_type xml.elements['results-start']
      @events            = nil
    end

    attr_reader :results_returned, :results_available, :results_start
    attr_accessor :events
  end

  class AtndEvent
    # XML オブジェクト
    def initialize(event)
      # 共通データ
      @accepted = AtndAPIUtil::to_ruby_type event.elements['accepted']
      @event_id = AtndAPIUtil::to_ruby_type event.elements['event-id']
      @updated_at = AtndAPIUtil::to_ruby_type event.elements['updated-at']
      @title = AtndAPIUtil::to_ruby_type event.elements['title']
      @waiting = AtndAPIUtil::to_ruby_type event.elements['waiting']
      @event_url = AtndAPIUtil::to_ruby_type event.elements['event-url']
      @limit = AtndAPIUtil::to_ruby_type event.elements['limit']
      
      # 出席情報の場合
      @users = []
      event.elements.each('users/user') do |user|
        @users << AtndUser.new(user)
      end
  
      # イベント情報の場合
      @place = AtndAPIUtil::to_ruby_type event.elements['place']
      @lon = AtndAPIUtil::to_ruby_type event.elements['lon']
      @ended_at = AtndAPIUtil::to_ruby_type event.elements['ended-at']
      @url = AtndAPIUtil::to_ruby_type event.elements['url']
      @owner_nickname = AtndAPIUtil::to_ruby_type event.elements['owner-nickname']
      @catch = AtndAPIUtil::to_ruby_type event.elements['catch']
      @description = AtndAPIUtil::to_ruby_type event.elements['description']
      @owner_id = AtndAPIUtil::to_ruby_type event.elements['owner-id']
      @lat = AtndAPIUtil::to_ruby_type event.elements['lat']
      @address = AtndAPIUtil::to_ruby_type event.elements['address']
      @started_at = AtndAPIUtil::to_ruby_type event.elements['started-at']
    end
    
    attr_reader :accepted, :event_id, :updated_at, :title, :waiting, :event_url, :limit
    attr_reader :users
    attr_reader :place, :lon, :ended_at, :url, :owner_nickname, :catch, :description, :owner_id, :lat, :address, :started_at
  end

  class AtndUser
    def initialize(user)
      @status = AtndAPIUtil::to_ruby_type user.elements['status']
      @nickname = AtndAPIUtil::to_ruby_type user.elements['nickname']
      @user_id = AtndAPIUtil::to_ruby_type user.elements['user-id']
    end
    attr_reader :status, :nickname, :user_id
  end


  require 'time'
  module AtndAPIUtil
    # REXML::Element
    def self.to_ruby_type(element)

      # 子要素が取得できない場合は nil を返す
      return nil if element.nil?

      # 要素が無い場合、属性に nil が付くので、値が true であれば nil を返す
      if element.attributes['nil']
        return nil if element.attributes['nil'] == 'true'
      end

      val = nil
      element_type = element.attributes['type'] 
      element_type = element_type.downcase if element_type
      case element_type
      when 'integer'
        val = element.text.to_i
      when 'decimal'
        val = element.text.to_f
      when 'datetime'
        val = Time.parse(element.text)
      else
        val = element.text
      end
      return val
    end
  end
end
