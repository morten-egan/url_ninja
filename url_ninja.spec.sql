create or replace package url_ninja

as

	/** This is a URL utility to manipulate and create URL constructs in plsql
	* @author Morten Egan
	* @version 0.0.1
	* @project URL_NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	-- Types and records
	type parm_list is table of varchar2(4000) index by varchar2(500);
	type url_rec is record (
		scheme					varchar2(20)
		, authority				varchar2(500)
		, path					varchar2(4000)
		, parameters			varchar2(4000)
		, query					varchar2(4000)
		, fragment				varchar2(4000)
		, username				varchar2(100)
		, password				varchar2(100)
		, hostname				varchar2(500)
		, port					number(6,0)
	);

	/** Parse a URI into its different components as a url_rec according to RFC 3986
	* @author Morten Egan
	* @param urlstring The URL to parse
	* @return url_rec The URL record, where the different URL components are split up.
	*/
	function urlparse (
		urlstring						in				varchar2
		, scheme						in				varchar2 default 'http'
	)
	return url_rec;

	/** Parse a url_rec back into a full URL string
	* @author Morten Egan
	* @param parsed_url The url_rec of the parsed URL string
	* @return varchar2 The urlstring that is the result of the url_rec beeing put back together.
	*/
	function urlunparse (
		parsed_url						in				url_rec
	)
	return varchar2;

	/** Build a get url from a base url and a list of parameters in the form of a associative array
	* @author Morten Egan
	* @param base_url The base URL to append the GET parameters to
	* @param parameter_list The list of parameters and values in the form of a parm_list.
	* @return varchar2 The full URL including the get parameters
	*/
	function build_get_url (
		base_url						in				varchar2
		, parameter_list				in				parm_list
	)
	return varchar2;

end url_ninja;
/