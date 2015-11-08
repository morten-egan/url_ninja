create or replace package body url_ninja

as

	function urlparse (
		urlstring						in				varchar2
		, scheme						in				varchar2 default 'http'
	)
	return url_rec
	
	as
	
		l_ret_val						url_rec;

		-- Location and semantic controls
		l_scheme_seperation				number := 0;
		l_scheme_location				number := 0;
		l_has_userinfo					number := 0;
		l_has_path						number := 0;
		l_has_query_params				number := 0;
		l_has_fragments					number := 0;
	
	begin
	
		dbms_application_info.set_action('urlparse');

		-- Initiate return values.
		l_ret_val.scheme := '';
		l_ret_val.authority := '';
		l_ret_val.path := '';
		l_ret_val.parameters := '';
		l_ret_val.query := '';
		l_ret_val.fragment := '';
		l_ret_val.username := null;
		l_ret_val.password := null;
		l_ret_val.hostname := null;
		l_ret_val.port := null;

		l_scheme_seperation := instr(urlstring,'//');
		l_scheme_location := 1;

		-- Set scheme
		if l_scheme_seperation > 0 then
			l_ret_val.scheme := replace(substr(urlstring, l_scheme_location, l_scheme_seperation - 1), ':');
		else
			l_ret_val.scheme := scheme;
		end if;

		-- Check for path element
		if l_scheme_seperation > 0 then
			l_has_path := instr(urlstring, '/', l_scheme_seperation + 3);
		else
			l_has_path := 1;
		end if;

		-- Check if we have a query part of the urlstring
		l_has_query_params := instr(urlstring, '?');

		-- Check if we have a fragment part of the urlstring
		l_has_fragments := instr(urlstring, '#');

		-- Set authority
		if l_scheme_seperation > 0 then
			if l_has_path > 1 then
				l_ret_val.authority := substr(urlstring, l_scheme_seperation + 2, (l_has_path - l_scheme_seperation) - 2);
			elsif l_has_query_params > 0 then 
				l_ret_val.authority := substr(urlstring, l_scheme_seperation + 2, (l_has_query_params - l_scheme_seperation) -2);
			elsif l_has_query_params = 0 and l_has_fragments > 0 then
				l_ret_val.authority := substr(urlstring, l_scheme_seperation + 2, (l_has_fragments - l_scheme_seperation) - 2);
			else
				l_ret_val.authority := substr(urlstring, l_scheme_seperation + 2);
			end if;
		end if;

		-- Check for userinfo in authority string
		l_has_userinfo := instr(l_ret_val.authority, '@');

		-- Extract the path
		if l_has_path = 1 then
			l_ret_val.path := urlstring;
		else
			if l_has_query_params > 0 then
				l_ret_val.path := substr(urlstring, l_has_path, (l_has_query_params - l_has_path));
			elsif l_has_query_params = 0 and l_has_fragments > 0 then
				l_ret_val.path := substr(urlstring, l_has_path, (l_has_fragments - l_has_path));
			else
				l_ret_val.path := substr(urlstring, l_has_path);
			end if;
		end if;

		-- Extract the query string
		if l_has_query_params > 0 then
			if l_has_fragments > 0 then
				l_ret_val.query := substr(urlstring, l_has_query_params + 1, (l_has_fragments - l_has_query_params) - 1);
			else
				l_ret_val.query := substr(urlstring, l_has_query_params + 1);
			end if;
		end if;

		-- Extract the fragments
		if l_has_fragments > 0 then
			-- Fragment is always the last part
			l_ret_val.fragment := substr(urlstring, l_has_fragments + 1);
		end if;

		-- Set the hostname and port
		if length(l_ret_val.authority) > 1 then
			if instr(l_ret_val.authority, ':') > 0 then
				if l_has_userinfo > 0 then
					l_ret_val.hostname := substr(l_ret_val.authority, l_has_userinfo + 1, instr(l_ret_val.authority, ':', 1, 2) - 1);
					l_ret_val.port := substr(l_ret_val.authority, instr(l_ret_val.authority, ':', 1, 2) + 1);
				else
					l_ret_val.hostname := substr(l_ret_val.authority, 1, instr(l_ret_val.authority, ':') - 1);
					l_ret_val.port := substr(l_ret_val.authority, instr(l_ret_val.authority, ':') + 1);
				end if;
			else
				l_ret_val.hostname := l_ret_val.authority;
			end if;
		end if;

		-- Set the username and password
		if l_has_userinfo > 0 then
			l_ret_val.username := substr(l_ret_val.authority, 1, l_has_userinfo - 1);
			-- Check if there is a password as well
			if instr(l_ret_val.username, ':') > 0 then
				l_ret_val.password := substr(l_ret_val.username, instr(l_ret_val.username, ':') + 1);
				l_ret_val.username := substr(l_ret_val.username, 1, instr(l_ret_val.username,':') - 1);
			end if;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end urlparse;

	function urlunparse (
		parsed_url						in				url_rec
	)
	return varchar2
	
	as
	
		l_ret_val			varchar2(32000);
	
	begin
	
		dbms_application_info.set_action('urlunparse');

		-- First we add the scheme
		if parsed_url.scheme = '' then
			l_ret_val := 'http://';
		else
			l_ret_val := parsed_url.scheme || '://';
		end if;

		l_ret_val := l_ret_val || parsed_url.authority;

		if parsed_url.path is not null then
			l_ret_val := l_ret_val || parsed_url.path;
		end if;

		if parsed_url.query is not null then
			l_ret_val := l_ret_val || '?' || parsed_url.query;
		end if;

		if parsed_url.fragment is not null then
			l_ret_val := l_ret_val || '#' || parsed_url.fragment;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end urlunparse;

	function build_get_url (
		base_url						in				varchar2
		, parameter_list				in				parm_list
	)
	return varchar2
	
	as
	
		l_ret_val			varchar2(32000) := base_url;
		l_parm_idx			varchar2(500);
		l_is_first			boolean := true;
	
	begin
	
		dbms_application_info.set_action('build_get_url');

		if parameter_list.count > 0 then
			l_parm_idx := parameter_list.first;
			while l_parm_idx is not null loop
				if l_is_first then
					l_ret_val := l_ret_val || '?' || l_parm_idx || '=' || utl_url.escape(parameter_list(l_parm_idx));
					l_is_first := false;
				else
					l_ret_val := l_ret_val || '&' || l_parm_idx || '=' || utl_url.escape(parameter_list(l_parm_idx));
				end if;
				l_parm_idx := parameter_list.next(l_parm_idx);
			end loop;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end build_get_url;

begin

	dbms_application_info.set_client_info('url_ninja');
	dbms_session.set_identifier('url_ninja');

end url_ninja;
/