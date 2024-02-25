package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type SQSMessageBody struct {
	Receiver          string `json:"receiver"`
	Text              string `json:"text"`
	IsMarkdownEnabled bool   `json:"isMarkdownEnabled"`
}

type TelegramSendMessageRequest struct {
	ChatID    string `json:"chat_id"`
	Text      string `json:"text"`
	ParseMode string `json:"parse_mode,omitempty"`
}

func handler(event events.SQSEvent) error {
	for _, record := range event.Records {
		err := processMessage(record)
		if err != nil {
			return err
		}
	}
	log.Println("done")
	return nil
}

func processMessage(record events.SQSMessage) error {
	log.Printf("Processed message %s\n", record.Body)

	sqsMessageBody := SQSMessageBody{}
	json.Unmarshal([]byte(record.Body), &sqsMessageBody)

	var request TelegramSendMessageRequest
	if sqsMessageBody.IsMarkdownEnabled {
		request = TelegramSendMessageRequest{sqsMessageBody.Receiver, sqsMessageBody.Text, "MarkdownV2"}
	} else {
		request = TelegramSendMessageRequest{sqsMessageBody.Receiver, sqsMessageBody.Text, ""}
	}
	sendMessage(request)

	return nil
}

func sendMessage(telegramSendMessageRequest TelegramSendMessageRequest) {
	log.Println("Sending message")

	//TODO: remove this ID
	url := "https://api.telegram.org/bot" + os.Getenv("APP_TELEGRAM_TOKEN") + "/sendMessage"

	telegramSendMessageRequestJSON, err := json.Marshal(telegramSendMessageRequest)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer([]byte(telegramSendMessageRequestJSON)))
	if err != nil {
		fmt.Println("Error creating the request")
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error sending the request")
	}

	defer resp.Body.Close()

	fmt.Println("Response Status:", resp.Status)

	respBody, err := io.ReadAll(resp.Body)

	if err != nil {
		fmt.Println("Error reading the response body")
	}

	fmt.Println(string(respBody))
}

func main() {
	lambda.Start(handler)
}
