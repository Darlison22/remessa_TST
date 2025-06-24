

Esse script verifica as possiveis causas de não conseguir remeter um processo para o TST.

As causas podem ser:

1 - Endereços das partes / advogados que podem não está em registro na tabela tb_cep;

2 - Campos: id_uf_oab, nr_aob ou in_validado na tabela tb_pessoa_advogado estarem nulos, indicando que o advogado daquele processo está inativo;

3 - Variaveis de fluxo com lixo na tabela jbpm_variableinstance.

------------------------------------------------------------------------

Tendo em vista isso, o script mostra as partes do processo que estão com registro de endereço errado. Ademais, também mostra os advogados que estáo improprios para participar do processo.
E por fim, mostra as variaveis de fluxo com lixo para ser feita a exclusão desses registros.




