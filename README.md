# Введение к русскоязычному переводу

Эта книга представляет собой перевод «The Rust Programming Language». Оригинал
книги расположен [здесь][original].

Перевод окончен и соответствует stable версии книги на момент выхода Rust 1.2 stable.
Могут встречаться несоответсвия оригиналу книги, но написанное здесь актуально
для любого Rust 1.x, поскольку Rust гарантирует стабильность языка в пределах
мажорной версии.

**ВНИМАНИЕ!** Если вы видите несоответствие примеров или текста реальному
  поведению, пожалуйста, создайте [задачу][error] или сразу делайте Pull Request
  с исправлениями. Мы не кусаемся и рады исправлениям! :wink:

* [Читать книгу](http://ruRust.github.io/rust_book_ru/)
* [Скачать в PDF](https://raw.githubusercontent.com/ruRust/rust_book_ru/gh-pages/converted/rustbook.pdf)
* [Скачать в EPUB](https://raw.githubusercontent.com/ruRust/rust_book_ru/gh-pages/converted/rustbook.epub)
* [Скачать в MOBI](https://raw.githubusercontent.com/ruRust/rust_book_ru/gh-pages/converted/rustbook.mobi)

# Полезные ссылки

Чаты                                   | Ссылки
---------------------------------------|--------
для обсуждения языка, получения помощи | [![Join the chat at https://gitter.im/ruRust/general](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ruRust/general?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
для обсуждения самой книги и вопросов перевода | [![Join the chat at https://gitter.im/ruRust/rust_book_ru](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ruRust/rust_book_ru?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![ruRust/rust_book_ru](http://issuestats.com/github/ruRust/rust_book_ru/badge/pr?style=flat)](http://issuestats.com/github/ruRust/rust_book_ru)
[![ruRust/rust_book_ru](http://issuestats.com/github/ruRust/rust_book_ru/badge/issue?style=flat)](http://issuestats.com/github/ruRust/rust_book_ru)

[Мы на Хабре](http://habrahabr.ru/post/266813/)

# Соавторам

## С чего начать

Есть некоторое количество очень простых проблем. Это
[опечатки](https://github.com/ruRust/rust_book_ru/labels/%D0%BE%D0%BF%D0%B5%D1%87%D0%B0%D1%82%D0%BA%D0%B0),
и, взяв одну из таких задач, вы сможете легко поучаствовать в переводе
и очень нам поможете.

Не бойтесь code review, у нас не принято наезжать на новичков. :smile:

## Сборка

Если вы занялись инфраструктурой, вам понадобится проверять свою работу
локально.

Сейчас самый простой собрать книгу локально: это проделать те же действия, что
делает Travis. Смотрите файл `.travis.yml`, разделы `install`, `before_script`,
`script`, `after_success`. Они должны быть достаточно понятны сами по себе.

## Тестирование

Если вы изменили инфраструктуру, следует проверить изменения. Проверка зависит
от компонента, в который вы внесли изменение.

Если это стили и генерация книги - нужно сгенерировать книгу локально и
посмотреть, что всё работает как надо. Конвейер преобразования HTML-версии в
другие варианты проверяется так же.

Если вы внесли изменения в скрипты, вызываемые Travis, или в сам `.travis.yaml`,
пожалуйста, следите за статусом сборки - он отображается в PR. PR, который не
проходит сборку, принят не будет.

## Где получить помощь

У этого репозитория есть чат-комната на Gitter. Если у вас возник
вопрос по задаче или по тому, что вы взялись делать, как перевести
какой-то термин или как собрать книгу локально - вам
[сюда](https://gitter.im/ruRust/rust_book_ru).

## Для опытных

[Правила перевода](https://github.com/ruRust/rust_book_ru/wiki/Правила).

## Благодарности

Выражаем благодарность [всем, кто принимал участие в создании этой
книги][authors].

От @kgv: «Хочу поблагодарить моих родителей: **Таню** и **Володю**. Без них не
было бы этой книги».

## Ошибки

Если вы встретили ошибку или неточность, пожалуйста, [напишите о ней][error].

## Ресурсы

* rustbook расположен [здесь][rustbook]
* репозиторий расположен [здесь][github]

[authors]: https://github.com/ruRust/rust_book_ru/blob/master/AUTHORS.md
[original]: https://doc.rust-lang.org/book
[github]: https://github.com/ruRust/rust_book_ru
[error]: https://github.com/ruRust/rust_book_ru/issues
[rustbook]: http://ruRust.github.io/rust_book_ru
