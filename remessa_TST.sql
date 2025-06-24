



create or replace function remessa_TST (p_nr_processo varchar)
returns void as $$
declare

	v_id_uf_oab integer;
	v_nr_oab varchar;
	v_in_validado boolean;
	v_nm_usuario_parte varchar;
	v_nm_advogado_parte varchar;
	v_nm_logradouro varchar;
	v_nr_cep varchar;
	v_cpf_advogado varchar;
	v_id_ bigint; -- id das variaveis de fluxo de lixo


	id_advogado integer;
	v_cpf_repetidos_array_1  varchar [];
	v_cpf_repetidos_array_2 varchar [];
	v_cpf_repetido varchar;
	v_verificador integer;
	v_posicao_cpf integer;
	i integer := 1;
	v_posicao_array_cpf_repetido integer [];
	v_cont integer := 1;

begin

		
			-- Listas as partes e os endereços com CEP
			raise notice '====================    PARTES DO PROCESSO    +    ENDERECOS     =====================================';
			raise notice '';
			
			raise notice '';
			for v_nm_usuario_parte, v_nm_advogado_parte, v_nr_cep, v_nm_logradouro in
			select 
				tul.ds_nome as usuario_parte,
				usuario_advogado.ds_nome  as usuario_advogado,
				tc.nr_cep,
				te.nm_logradouro
			from pje.tb_processo tp 
			inner join pje.tb_processo_parte tpp on tpp.id_processo_trf = tp.id_processo
			inner join pje.tb_tipo_parte ttp on tpp.id_tipo_parte = ttp.id_tipo_parte 
			left  join pje.tb_processo_parte_endereco tppe on tppe.id_processo_parte = tpp.id_processo_parte
			left  join pje.tb_endereco te on tppe.id_endereco = te.id_endereco
			left join pje.tb_cep tc on te.id_cep = tc.id_cep 
			inner  join pje.tb_proc_parte_represntante tppr on tppr.id_processo_parte = tpp.id_processo_parte
			inner  join pje.tb_usuario_login usuario_advogado on tppr.id_representante = usuario_advogado.id_usuario
			left join pje.tb_usuario_login tul on te.id_usuario = tul.id_usuario
			where tp.nr_processo = p_nr_processo
			loop
				
			--Listar aqui todas as partes e os endereços com cep
			if (v_nr_cep is null) then
				raise notice 'usuario_parte:  %', v_nm_usuario_parte;
				raise notice 'advogado_parte:  %', v_nm_advogado_parte;
				raise notice 'numero_cep:  %', v_nr_cep;
				raise notice 'logradouro:  % ', v_nm_logradouro;
				raise notice ' ';
				raise notice '------------------------';
				v_cont := v_cont + 1;
			end if;
			
		end loop;

		if v_cont = 1  then 
			raise notice 'Os endereços das partes estão ok em relação a tabela tb_cep';	
		end if;

			raise notice ' ';
			raise notice '==============================   ADVOGADOS INVATIVOS   ===================================================';
			raise notice' ';
		
--pegar os cpfs repetidos para não imprimir a mesma parte representante duas ou mais vezes
	for v_nm_advogado_parte, v_cpf_advogado, v_id_uf_oab, v_nr_oab, id_advogado, v_in_validado  in
			select 
				usario_adv.ds_nome,
				usario_adv.ds_login,		
			   	adv.id_uf_oab, 
				adv.nr_oab, 
				usario_adv.id_usuario,
				case 
					when adv.in_validado = 'S' then true
					when adv.in_validado = 'N' then false
				end as in_validado
		from pje.tb_processo tp 
		inner join pje.tb_processo_parte parte on parte.id_processo_trf = tp.id_processo
		inner join pje.tb_tipo_parte tipo_parte on tipo_parte.id_tipo_parte = parte.id_tipo_parte 
	 	left join  pje.tb_pessoa_advogado adv on adv.id = parte.id_pessoa
		left  join pje.tb_proc_parte_represntante representante on representante.id_processo_parte = parte.id_processo_parte 
	 	inner join pje.tb_usuario_login usario_adv on usario_adv.id_usuario = representante.id_representante 
		where 1=1
		and tp.nr_processo = p_nr_processo
		loop

			if (v_id_uf_oab is null and v_nr_oab is null and (v_in_validado is null or v_in_validado = 'N') ) then	
					v_cpf_repetidos_array_1 := array_append(v_cpf_repetidos_array_1, v_cpf_advogado);
					v_cpf_repetidos_array_2 := array_append(v_cpf_repetidos_array_2, v_cpf_advogado);
			end if;			
		end loop; 

	---------------------------
	raise notice '';
	raise notice '';


		--eliminar os cpf repetidos 
		v_verificador := 0;
		v_posicao_cpf := 0;
		foreach v_cpf_repetido in array v_cpf_repetidos_array_1
		loop
				foreach v_cpf_advogado in array v_cpf_repetidos_array_2	
				loop

					v_posicao_cpf := v_posicao_cpf + 1;

					if(v_cpf_repetido = v_cpf_advogado and v_cpf_advogado is not null and v_cpf_repetido is not null) then
						v_verificador := v_verificador + 1;
						v_posicao_array_cpf_repetido := array_append(v_posicao_array_cpf_repetido, v_posicao_cpf);
					end if;

				end loop;

				if(v_verificador > 1) then
					
					while i < v_verificador loop
						v_cpf_repetidos_array_1[v_posicao_array_cpf_repetido[i]] := null;
						v_cpf_repetidos_array_2[v_posicao_array_cpf_repetido[i]] := null;
						i := i + 1;
					end loop;
					
				end if;
				i := 1;
				v_verificador := 0;
				v_posicao_cpf := 0;
				v_posicao_array_cpf_repetido := '{}';
		end loop;

--------------------------------------------------------
			--imprimir os advogados que estão irregulares
			foreach v_cpf_advogado in array v_cpf_repetidos_array_1
			 loop

				select 
				usario_adv.ds_nome,
			   	adv.id_uf_oab, 
				adv.nr_oab, 
				case 
					when adv.in_validado = 'S' then true
					when adv.in_validado = 'N' then false
				end as in_validado 
				into v_nm_advogado_parte,  v_id_uf_oab, v_nr_oab,  v_in_validado
				from pje.tb_processo tp 
				inner join pje.tb_processo_parte parte on parte.id_processo_trf = tp.id_processo
				inner join pje.tb_tipo_parte tipo_parte on tipo_parte.id_tipo_parte = parte.id_tipo_parte 
			 	left join  pje.tb_pessoa_advogado adv on adv.id = parte.id_pessoa
				left  join pje.tb_proc_parte_represntante representante on representante.id_processo_parte = parte.id_processo_parte 
			 	inner join pje.tb_usuario_login usario_adv on usario_adv.id_usuario = representante.id_representante 
				where 1=1
				and tp.nr_processo = p_nr_processo
				and usario_adv.ds_login = v_cpf_advogado;
				

					--Mostrar aqui os advogados com os campos v_id_uf, v_nr_oab e v_invalidado iguais a nulos
					if (v_id_uf_oab is null and v_nr_oab is null and (v_in_validado is null or v_in_validado = 'N') and v_cpf_advogado is not null ) then	
						
								raise notice 'nome_advogado:  %', v_nm_advogado_parte;
								raise notice 'cpf_advogado:  %', v_cpf_advogado;
								raise notice 'id_uf_oab:  %', v_id_uf_oab;
								raise notice 'nr_oab:  %', v_nr_oab;
								raise notice 'in_validado:  %', v_in_validado;
								raise notice ' ';
								raise notice '------------------------';		
					end if;		
		
		end loop;


				raise notice '';
				raise notice '=====================   VARIAVEIS DE FLUXO COM LIXO PARA SERREM EXCLUIDAS       ===================================';
				raise notice '';
			--verificar se há variaveis de fluxo com lixo, e se houver, deleta-las
			for v_id_ in
					select 
						jv.id_
					from pje_jbpm.jbpm_variableinstance jv 
					where 1=1
					and (
					name_ ilike any (
						array[
							'%minutaemElaboracao', 'minutaarquivamento',
							'%modelo', '%temporario', '%ple:atoProferido',
							'%temp', '%Expedientes%', '%text%',
							'%voto%', 'PAC%', '%processoemoutrainstancia%',
							'veioAguardarPrazoRec%', 'cancelarTarefa'
						]
					)
					or bytearrayvalue_ is not null
					)
					and processinstance_ in (
						select 
							id_proc_inst
						from pje.tb_processo_instance
						where id_processo in (
							select 
								id_processo
							from pje.tb_processo
							where nr_processo ilike any (
									array [p_nr_processo]
							)
						)	
					)
			loop
					if(v_id_ is not null) then
						
						raise notice 'delete from pje_jbpm.jbpm_variableinstance where id_ = %;', v_id_;

					end if;
			
	
			end loop;

end;
$$ language plpgsql;






select remessa_TST ('0000072-63.2021.5.07.0023');




--------------------------------------------------------------------















