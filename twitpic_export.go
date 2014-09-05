package main

//=============================================================================
// http://twitpic.com/ 閉鎖に伴うデータのバックアップツール。
// ツイートと画像をローカルPCに保存する。
//=============================================================================

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

func main() {
	//引数のチェック。
	if len(os.Args) == 1 {
		fmt.Printf("[ERROR] command line error\n        example: twitpic_export.exe namahage")
		fmt.Println("")
		os.Exit(0)
	}

	username := os.Args[1]

	//出力ディレクトリの作成。
	os.MkdirAll(fmt.Sprintf(".\\%s\\", username), 0777)

	//ダンプ
	total := 0
	for i := 1; i < 1000; i++ {
		fmt.Printf("=== page %d START ===", i)
		fmt.Println("")
		r := savedata(username, i)
		fmt.Printf("=== page %d END gets = %d ===", i, r)
		fmt.Println("")
		total += r

		if r == 0 {
			break
		}
	}

	//＼(^o^)／
	fmt.Printf("\n\n\n=== JOB END ===\ntotal get photos = %d\n\n", total)
	fmt.Printf("Please check the count of the photos on this page.\nhttp://twitpic.com/photos/%s", username)
	fmt.Println("")
}

//=============================================================================
//説明  ：ユーザー名＋ページを指定し、xmlと画像を保存する。
//戻り値：取得できた写真の数。
//=============================================================================
func savedata(username string, page int) int {
	//戻り値初期化。
	rtn := 0

	//保存ディレクトリ
	dir := fmt.Sprintf(".\\%s\\", username)

	//json取得 リトライ3回。
	fmt.Println("get json...")
	jsonurl := fmt.Sprintf("http://api.twitpic.com/2/users/show.json?username=%s&page=%d", username, page)
	resp, err := http.Get(jsonurl)
	if err != nil || resp.StatusCode != 200 {
		fmt.Println("sleep 10s")
		time.Sleep(10 * 1000 * 1000 * 1000) // 10秒
		resp, err = http.Get(jsonurl)
	}
	if err != nil || resp.StatusCode != 200 {
		fmt.Println("sleep 10s")
		time.Sleep(10 * 1000 * 1000 * 1000) // 10秒
		resp, err = http.Get(jsonurl)
	}

	//json取得に失敗した場合、そのページをスキップ。
	if err != nil {
		fmt.Printf("[ERROR] json not not found")
		fmt.Println(err)
		return 0
	}

	//JSON→文字列
	defer resp.Body.Close()
	buff, err := ioutil.ReadAll(resp.Body)
	body := string(buff)

	//ツイートっぽいところを抜き出す。
	re, _ := regexp.Compile("{\"id\":\"[0-9]+\",\"short_id\".*?}")
	ids := re.FindAllString(body, -1)
	for index, value := range ids {
		fmt.Printf("%02d", index)
		fmt.Print(" ")

		id := ""
		tp := ""

		//ID
		re, _ = regexp.Compile("{\"id\":\"[0-9]+\",\"short_id\"")
		id = re.FindString(value)
		re, _ = regexp.Compile("[^0-9]")
		id = re.ReplaceAllString(id, "")

		//拡張子
		re, _ = regexp.Compile("\"type\":\".*?\"")
		tp = re.FindString(value)
		tp = strings.Replace(tp, "\"type\":\"", "", 1)
		tp = strings.Replace(tp, "\"", "", 1)

		//jpg,png,gifだけ保存。
		if id != "" && (tp == "jpg" || tp == "png" || tp == "gif") {
			fmt.Printf("http://d3j5vwomefv46c.cloudfront.net/photos/large/%s.%s", id, tp)
			fmt.Println("")
			rtn += saveimage(fmt.Sprintf("http://d3j5vwomefv46c.cloudfront.net/photos/large/%s.%s", id, tp), dir)
		} else {
			fmt.Printf("[ERROR] id=%s , type=%s", id, tp)
			fmt.Println("")
		}
	}

	//xml保存
	if rtn != 0 {
		fmt.Println("save xml...")
		os.Remove(fmt.Sprintf("%s%d.xml", dir, page))
		saveimage(fmt.Sprintf("http://api.twitpic.com/2/users/show.xml?username=%s&page=%d&dammy=/%d.xml", username, page, page), dir)
	}

	return rtn
}

//=============================================================================
//説明  ：指定されたURLの画像を保存する。
//戻り値：成功=1,失敗=0
//=============================================================================
func saveimage(url string, filepath string) int {

	//取得ファイル名の決定
	filename := url
	re, _ := regexp.Compile("^.*/")
	filename = re.ReplaceAllString(filename, "")

	//存在確認。あったらスキップ
	_, err := os.Stat(filepath + filename)
	if err == nil {
		return 1
	}

	//取得
	response, err := http.Get(url)
	if err != nil || response.StatusCode != 200 {
		fmt.Println("sleep 10s")
		time.Sleep(10 * 1000 * 1000 * 1000) // 10秒
		response, err = http.Get(url)
	}
	if err != nil || response.StatusCode != 200 {
		fmt.Println("sleep 10s")
		time.Sleep(10 * 1000 * 1000 * 1000) // 10秒
		response, err = http.Get(url)
	}
	if err != nil {
		fmt.Println(err)
		return 0
	}
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		fmt.Println(err)
		return 0
	}
	sbody := string(body)
	re, _ = regexp.Compile("Error")
	if re.MatchString(sbody) {
		return 0
	}

	//保存
	ioutil.WriteFile(filepath+filename, body, 0666)

	//最終更新日時の反映
	t, err := time.Parse(
		"Mon, 02 Jan 2006 15:04:05 MST",      // スキャンフォーマット
		response.Header.Get("Last-Modified")) // パースしたい文字列
	if err == nil {
		os.Chtimes(filepath+filename, t, t)
	}
	return 1
}
