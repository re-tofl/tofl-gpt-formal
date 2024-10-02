package main

import (
	"bufio"
	"fmt"
	"github.com/VyacheslavIsWorkingNow/tfl/lab1/parser"
	"log"
	"os"
	"os/exec"
)

// TODO: заменить паники на что-то более нежное

const (
	fileReadName = "fileRead.txt"
	output       = "solver.smt2"
)

func main() {

	//example := "f(g(x), w(g(y), z)) -> g(f(x, y))\nh(g(x)) -> s(y)\ns(y) -> g(f(x, y))"

	fmt.Println("Вы хотите написать выражение в файл или консоль?")
	fmt.Println("Интерактивный ввод: 1\nЧтение из файла: 2-9")

	var whereRead int
	_, wrErr := fmt.Scanf("%d", &whereRead)
	if wrErr != nil {
		log.Fatal(wrErr)
	}

	if whereRead == 1 {

		fileStdin, oErr := os.Create(fileReadName)
		if oErr != nil {
			log.Fatal(oErr)
		}
		if tErr := fileStdin.Truncate(0); tErr != nil {
			log.Fatal(tErr)
		}
		if _, sErr := fileStdin.Seek(0, 0); sErr != nil {
			log.Fatal(sErr)
		}
		fmt.Println("Введите текст для записи в файл (Ctrl+D для завершения ввода):")
		fmt.Println("Пример: 'h(g(x)) -> s(y)'")
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			expression := scanner.Text() + "\n"
			_, wErr := fileStdin.WriteString(expression)
			if wErr != nil {
				log.Fatal(wErr)
			}
		}

		if err := scanner.Err(); err != nil {
			log.Fatal(err)
		}
	}

	fileRead, rErr := os.Open(fileReadName)
	if rErr != nil {
		log.Fatal(rErr)
	}
	defer func() {
		_ = fileRead.Close()
	}()

	scanner := bufio.NewScanner(fileRead)

	example := ""
	for scanner.Scan() {
		example += scanner.Text() + "\n"
	}

	example = example[:len(example)-1]

	report, err := parser.Parse(example)
	if err != nil {
		log.Fatal(err)
	}

	file, oErr := os.Create(output)
	if oErr != nil {
		log.Fatal(oErr)
	}
	defer func() {
		_ = file.Close()
	}()

	_, wErr := file.WriteString(report)
	if wErr != nil {
		log.Fatal(wErr)
	}

	cmd := exec.Command("z3", output)

	result, eErr := cmd.CombinedOutput()
	if wErr != nil {
		log.Fatal(eErr)
	}

	fmt.Println("Результат выполнения команды:")
	fmt.Println(string(result))

}
