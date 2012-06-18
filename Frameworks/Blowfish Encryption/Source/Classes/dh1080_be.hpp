// Copyright (c) 2005 - 2007 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see License.txt for further information.

#include <map>
#include <string>
#include <openssl/dh.h>
#include <openssl/bn.h>

class dhclass {
public:
	dhclass();
	~dhclass();
	void reset();
	bool generate();
	bool compute();
	bool set_her_key(std::string &her_public_key);
	void get_public_key(std::string &s);
	void get_secret(std::string &s);
private:
	DH *dh;
	BIGNUM *herpubkey;
	std::string secret;
};

struct recvkeystruct {
	std::string sender;
	std::string keydata;
};

extern std::map<std::string, dhclass> dhs;
extern std::map<std::string, recvkeystruct> recvkeys;

void dh_base64encode(std::string &s);
void dh_base64decode(std::string &s);