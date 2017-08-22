class GetEnvelopDetailJob < ApplicationJob
  queue_as :default

  def perform(abnormal_id)
    abnormal = Abnormal.find(abnormal_id)
    response = RestClient.post 'www.diastarasia.com/Diastar/Envelop.do?action=searchEnvelop', {envelopID: abnormal.envelop}
    doc = Nokogiri::HTML.parse(response.body).to_s
    # 找出图片链接
    url = doc.scan(/\/I.+\.jpg/).first
    image_url = "http://www.diastarasia.com" + url
    abnormal.remote_image_url = image_url
    # 找出客户
    client = doc.scan(/客户.Client.*td>\s*.*td\>/).first.to_s.scan(/\<td.*td\>/).first.to_s.gsub(/(\<td\>|\<\/td\>)/, '')

    abnormal.client = client
    # 找出款号
    abnormal.model_no = doc.scan(/ByModelNo.*\"/).first.to_s.scan(/\=.*\"/).first.to_s.gsub(/(\=|\")/, '')
    # 找出头版交期
    first_date = doc.scan(/first.pc.*\s*\<.*\s*\<.*\s*.*/).first.to_s.scan(/\s20.*\-.*\-../).first.to_s.sub(/\s20/,'')
    # 找出出货期
    second_date = doc.scan(/Deliver.Date.*\s*.*\s*.*/).first.to_s.scan(/20.*\-.*\-../).first.to_s.sub(/20/,'')
    # 把头版交期或出货期存入原始交期栏位
    abnormal.raw_delivery = "【" << first_date << "】【" << second_date << "】"
    # 找出跟版
    genbanren = doc.scan(/跟版人.*\s*.*\s*.*/).first.to_s.scan(/\t....\r/).first.to_s.gsub(/(\s|.\s)/, '').sub(/\)/, '')
    # 找出跟单
    gendanren = doc.scan(/跟单..../).first.to_s.gsub(/跟单：/, '').sub(/\)/, '')
    # 把跟单和跟版存入业务员栏位中
    abnormal.merchandiser = '' << gendanren  << genbanren
    abnormal.save
  end
end
