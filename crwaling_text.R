# 패키지 설치
install.packages(c("rvest", "httr", "RSelenium","ggplot2", "dplyr","RSelenium"))



# 라이브러리 불러오기
library(httr)
library(rvest)
library(RSelenium)



# RSelenium을 이용해 R에서 크롬 열기
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4567L, browserName = "chrome")
remDr$open()
remDr$setWindowSize(width = 1200, height = 800)



# 데이터프레임 생성
df.crawling <- data.frame(index = 0, date = 0, title = 0, content = 0)



# 학사공지 페이지 주소
url.notification <- "https://www.hufs.ac.kr/hufs/11282/subview.do" 



# 해당 페이지 열기
remDr$navigate(url.notification)



# 인덱스번호 수집
index <- read_html(url.notification) %>% html_nodes("div._fnctWrap table tbody tr:not(.notice) td.td-num") %>% html_text()
index <- as.numeric(index[1])



# 첫번째 공지 클릭하기
element <- remDr$findElement(using = "css", value = "div.scroll-table tbody tr:not(.notice) a")
element$clickElement()



# while 루프 시작
while (TRUE) {
  tryCatch({

    # 페이지의 소스 가져오기
    notification.item <- remDr$getPageSource()[[1]]
    notification.item <- read_html(notification.item, encoding = "UTF-8")
    date <- notification.item %>% html_nodes("div.view-info div.view-detail dl.write dd") %>% html_text()
    title <- notification.item %>% html_nodes("div.board-view-info div.view-info h2") %>% html_text()
    content <- notification.item %>% html_nodes("div.view-con") %>% html_text()
    
    # factor에 저장
    item <- c(index, date, title, content[1]) # | index | date | title | content | 형식
    index <- index - 1 
    
    # 텍스트 정리
    item <- gsub("\n", "", item)
    item <- gsub("\t", "", item)
    
    # 데이터프레임에 열을 추가하여 새로 읽어온 텍스트 삽입
    df.crawling <- rbind(df.crawling, item)
    
    # 이전 글 클릭하기
    element <- remDr$findElement(using = "css", value = "main.contents div._fnctWrap div.view-navi dl:first-child dd a")
    Sys.sleep(5)
    element$clickElement() 
    
    
  }, error = function(e) {
    # 예외 처리 코드: 반복 종료
    print(e$message)
    break  # while 루프 종료
  })
}



# csv파일로 export
write.csv(df.crawling, file="C:/Users/admin/Desktop/noti_bachelor.csv", fileEncoding = "UTF-8")



# 페이지 및 포트 닫기
remDr$close()
pJS$stop()
