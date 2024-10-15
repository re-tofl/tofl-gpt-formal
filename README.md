# tofl-gpt-formal
- Для демонстрации работы в этой ветке добавлен человекочитаемый ввод (но в строгом соответствии с форматом). При запуске программы будет выведено приглашение на ввод TRS, а затем интерпретаций.
Предусмотрен вариант, когда пользователь не передаёт интерпретации. В таком случае запускается лаба прошлого года, написанная на Go, которая пытается доказать завершаемость TRS линейными интерпретациями. 

## Тесты
Пример ввода:
- TRS:
  ```
  f(x, y) -> h(x)
  h(x) -> g(x)
  ```
- Интерпретаций:
  ```
  f(x, y) = x * y^2
  h(t) = t + 5
  g(y) = y + 14
  ```
- То есть разделение левой и правой части TRS производится символом
  ```
  ->
  ```
- Разделение левой и правой части интерпретаций производится символом
  ```
  =
  ```
- Между всеми операторами и переменными ставится пробел (исключение - оператор возведения в степень ```^```)
## Установка необходимых пакетов

Перед запуском необходимо установить нужные пакеты. Для этого в консоли Julia, находясь в папке проекта, выполните следующие команды:

```julia
using Pkg
Pkg.add("HTTP")
Pkg.add("JSON")
Pkg.add("Random")
Pkg.add("Symbolics")
```
## Установка других  зависимостей

Для работы программы также необходим z3 и компилятор Go. Установить их можно командами:

```bash
sudo apt install golang
sudo apt install z3
```

## Запуск программы

Для запуска основной программы выполните команду:

```bash
julia src/main.jl
```

После запуска на экране появится сообщение с приглашением на ввод.

## Результат

В консоли, где запущена основная программа, будут выводиться переданные TRS, их интерпретации, шаги обработки и итоговый ответ. Также для отладки выводится строка с JSON, которая в дальнейшем будет отправляться в чат.
