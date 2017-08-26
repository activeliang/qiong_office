class GetModelNoDetailJob < ApplicationJob
  queue_as :default

  def perform(abnormal_id)

    abnormal = Abnormal.find(abnormal_id)

        model_no = abnormal.model_no

        url = "www.diastarasia.com/Diastar/loginAction.do?action=login"
        # 登入操作
        login_resp = RestClient.post url,{userName: '2145', password: '8523698'}


        cookies_id = login_resp.cookies.first[1]

        # 获取型号详情
        post_url = "http://www.diastarasia.com/Diastar/ModelNo.do?action=searchModelNo&SearchBy=ByModelNo&modelNo=" + model_no

        resp = RestClient.get post_url, {:cookies => {:JSESSIONID => cookies_id}}

        client = resp.body.scan(/客户\(Client\).*\s*.*/).first.scan(/\<td\>.*\>/).first.gsub(/(\<td\>|\<\/td\>)/, '')
        image_url = "http://www.diastarasia.com" + resp.body.scan(/\/I\/ModelNo.*\.jpg/).first

        envelop_url = "http://www.diastarasia.com" + resp.body.scan(/\/Diastar\/Enve.*\=\d{6}/).first

        envelop_resp = RestClient.get envelop_url

        # 找出跟版
        genbanren = envelop_resp.body.scan(/跟版人.*\s*.*\s*.*/).first.to_s.scan(/\t....\r/).first.to_s.gsub(/(\s|.\s)/, '').sub(/\)/, '')
        # 找出跟单
        gendanren = envelop_resp.body.scan(/跟单..../).first.to_s.gsub(/跟单：/, '').sub(/\)/, '')

  abnormal.client = client
  abnormal.remote_image_url = image_url
  abnormal.merchandiser = '' + genbanren + gendanren
  abnormal.save
  # binding.pry

  end
end
