#For single publisher of rokomari
require 'nokogiri'
require 'httparty'
require 'byebug'
require 'csv'

def scraper
    #url = "https://www.rokomari.com//book/publisher/5542/abc?ref=apb_pg1_p41&page=1"
    puts "Insert the publisher URL"
    url = gets.chomp
    url= url+"&page=1"
    a = url
    unparsed_page = HTTParty.get(url)
    parsed_page = Nokogiri::HTML(unparsed_page.body)

    product_array = Array.new

    products = parsed_page.css('div.book-list-wrapper')

    per_page = products.count
    page = 1
    total_products = parsed_page.css('div.col-lg-12').text.split(' ')[-2].to_i

    #last_page = (total_products.to_f / per_page.to_f).ceil
    if total_products > 0
      last_page = (total_products.to_f / per_page.to_f).ceil
    else
      last_page = page
    end

   

    n=0
    #publisher_name = parsed_page.css('li.breadcrumb-item.active').text
    @publisher_name
    while page <= last_page
        x= a.delete_suffix(a[-1]) + "#{page}"
        pagination_url = x
        #pagination_url = "https://rokomari.com/book/publisher/369/seba-prokashony?ref=mm_p5&page=#{page}"
        pagination_unparsed_page = HTTParty.get(pagination_url)
        pagination_parsed_page = Nokogiri::HTML(pagination_unparsed_page.body)
        pagination_products = pagination_parsed_page.css('div.book-list-wrapper')

        pagination_products.each  do|product|
          product ={
            title: product.css('p.book-title').text,
            author: product.css('p.book-author').text,
            original_price: product.css('strike.original-price.pl-2').text,
            discounted_price: product.css('span').text,
            url: "https://rokomari.com/"+product.css('a')[0].attributes["href"].value,
            image: product.css('img')[0].attributes["data-src"].text
          }

          if product[:original_price] == ""
            product[:original_price] = product[:discounted_price]
            product[:discounted_price]= ""
          end

          #byebug
          #puts "Added Title : #{product[:title]}"
          #puts " "
          book_url = product[:url]
          book_unparsed_page = HTTParty.get(book_url)
          book_parsed_page = Nokogiri::HTML(book_unparsed_page.body)

          byebug
          
            book = {
              summary: book_parsed_page.css('div.details-book-additional-info__content-summery.truncate').text.gsub(/\t\n\s+/,"").strip
            }

          book_perser = book_parsed_page.css('#book-additional-specification > table > tr')
          @book_summary = {}

          book_perser.each do |tr|
            label=tr.css('td[1]').text
            value=tr.css('td[2]').text.split(',').map { |s| s.strip }.join(',')
            scrap_info = { label => value }
            @book_summary=@book_summary.merge(scrap_info)
            #byebug
          end

          #byebug
            product = product.merge(book)
            product = product.merge(@book_summary)
            product_array << product
            #@publisher_name = product["Publisher"]

            if product["Publisher"] != nil
              @publisher_name = product["Publisher"]
            else
              @publisher_name = "blank_name"
            end
            @publisher_name = @publisher_name.gsub("/"," ")

            
      end

      page += 1
    end
    temp = {
          title: " ",
          author: "",
          original_price: " ",
          discounted_price: " ",
          url: " ",
          image: " ",
          summary: " ",
          "Title" => " ",
          "Author"=>" ",
          "Translator"=>" ",
          "Editor" => " ",
          "Publisher"=>" ",
          "ISBN"=>" ",
          "Edition"=>" ",
          "Number of Pages"=>" ",
          "Country"=>" ",
          "Language"=>" "


        }
    #byebug
    #binding.pry
    #byebug
      CSV.open("rokomari_v2/#{@publisher_name}.csv",'w') do |csv|


        csv << ['title','author','original_price','discounted_price','url','image','summary',
              'title_in_specification','author_in_specification','translator_in_specification',
              'editor_in_specification','publisher_in_specification','isbn_in_specification',
              'edition_in_specification','number_of_pages_in_specification','country_in_specification',
              'language_in_specification']
        product_array.each do |product|
          product = temp.merge(product)
          csv << CSV::Row.new(product.keys,product.values)
        end

        puts "#{@publisher_name}.csv is created"
      end
end
scraper
