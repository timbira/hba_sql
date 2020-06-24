# hba_sql

## Introdução
Uma tarefa comum no dia a dia de quem cuida de instâncias PostgreSQL são as regras de acesso definidas no arquivo [pg_hba.conf](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html) (Host-Based Authentication). Por se tratar de um arquivo texto com um formato bem específico, erros são comuns de ocorrer e difíceis de identificar.

Para minimizar problemas na edição deste arquivo, a equipe de Tecnologia da [uMov.me](https://www.umov.me) precisa de uma solução que facilite esta edição no dia a dia. Vamos fazer essa implementação ao vivo, construindo nesta live um mecanismo para manipular o pg_hba.conf usando comandos SQL como INSERT/UPDATE/DELETE/SELECT, simplificando assim essa tarefa que pode ser tão suscetível a erros. 

Este repositório contém todo o código produzido durante o LiveCoding que está disponível no canal da [Timbira](https://www.timbira.com.br) no [Youtube](https://www.youtube.com/c/timbira).

Estamos usando a versão 12 do PostgreSQL que é a atual STABLE.

## Comandos/Funções úteis

* [regexp_split_to_array](https://www.postgresql.org/docs/12/functions-string.html#FUNCTIONS-STRING-OTHER): faz split de uma string em um array baseado em uma expressão regular como delimitador
* [string_to_array](https://www.postgresql.org/docs/12/functions-array.html#ARRAY-FUNCTIONS-TABLE): faz split de uma string em array baseado em outra string como delimitador.
* [unnest](https://www.postgresql.org/docs/12/functions-array.html#ARRAY-FUNCTIONS-TABLE): expande um array em um conjunto de linhas
* [pg_read_file](https://www.postgresql.org/docs/12/functions-admin.html#FUNCTIONS-ADMIN-GENFILE-TABLE): retorna o conteúdo de um arquivo texto

## Streaming

Youtube: https://www.youtube.com/watch?v=hPCTp4I50ms
