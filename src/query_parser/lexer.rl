#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include "parse.h"
#include "parser.h"
#include "../query_node.h"
#include "../stopwords.h"

/* forward declarations of stuff generated by lemon */
void RSQuery_Parse(void *yyp, int yymajor, QueryToken yyminor, QueryParseCtx *ctx);
void *RSQuery_ParseAlloc(void *(*mallocProc)(size_t));
void RSQuery_ParseFree(void *p, void (*freeProc)(void *));

%%{

machine query;

inf = ['+\-']? 'inf' $ 3;
number = '-'? digit+('.' digit+)? $ 2;

quote = '"';
or = '|';
lp = '(';
rp = ')';
lb = '{';
rb = '}';
colon = ':';
minus = '-';
tilde = '~';
star = '*';
rsqb = ']';
lsqb = '[';
escape = '\\';
escaped_character = escape (punct | space | escape);
term = (((any - (punct | cntrl | space | escape)) | escaped_character) | '_')+  $ 0 ;
prefix = term.star $1;
mod = '@'.term $ 1;

main := |*

  number => { 
    tok.s = ts;
    tok.len = te-ts;
    char *ne = (char*)te;
    tok.numval = strtod(tok.s, &ne);
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, NUMBER, tok, q);
    if (!q->ok) {
      fbreak;
    }
    
  };
  mod => {
    tok.pos = ts-q->raw;
    tok.len = te - (ts + 1);
    tok.s = ts+1;
    RSQuery_Parse(pParser, MODIFIER, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  inf => { 
    tok.pos = ts-q->raw;
    tok.s = ts;
    tok.len = te-ts;
    
    tok.numval = *ts == '-' ? -INFINITY : INFINITY;
    RSQuery_Parse(pParser, NUMBER, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  
  quote => {
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, QUOTE, tok, q);  
    if (!q->ok) {
      fbreak;
    }
  };
  or => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, OR, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  lp => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, LP, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  rp => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, RP, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  lb => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, LB, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  rb => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, RB, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
   colon => { 
     tok.pos = ts-q->raw;
     RSQuery_Parse(pParser, COLON, tok, q);
     if (!q->ok) {
      fbreak;
    }
   };
  

  minus =>  { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, MINUS, tok, q);  
    if (!q->ok) {
      fbreak;
    }
  };
  tilde => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, TILDE, tok, q);  
    if (!q->ok) {
      fbreak;
    }
  };
 star => {
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, STAR, tok, q);
    if (!q->ok) {
      fbreak;
    }
  };
  lsqb => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, LSQB, tok, q);  
    if (!q->ok) {
      fbreak;
    }  
  };
  rsqb => { 
    tok.pos = ts-q->raw;
    RSQuery_Parse(pParser, RSQB, tok, q);   
    if (!q->ok) {
      fbreak;
    } 
  };
  space;
  punct;
  cntrl;
  
  term => {
    tok.len = te-ts;
    tok.s = ts;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    if (!StopWordList_Contains(q->opts.stopwords, tok.s, tok.len)) {
      RSQuery_Parse(pParser, TERM, tok, q);
    } else {
      RSQuery_Parse(pParser, STOPWORD, tok, q);
    }
    if (!q->ok) {
      fbreak;
    }
  };
    prefix => {
    tok.len = te-ts - 1;
    tok.s = ts;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    
    RSQuery_Parse(pParser, PREFIX, tok, q);
    
    if (!q->ok) {
      fbreak;
    }
  };
  
*|;
}%%

%% write data;



QueryNode *Query_Parse(QueryParseCtx *q, char **err) {
  void *pParser = RSQuery_ParseAlloc(malloc);

  
  int cs, act;
  const char* ts = q->raw;
  const char* te = q->raw + q->len;
  %% write init;
  QueryToken tok = {.len = 0, .pos = 0, .s = 0};
  
  //parseCtx ctx = {.root = NULL, .ok = 1, .errorMsg = NULL, .q = q};
  const char* p = q->raw;
  const char* pe = q->raw + q->len;
  const char* eof = pe;
  
  %% write exec;
  

  if (q->ok) {
    RSQuery_Parse(pParser, 0, tok, q);
  }
  RSQuery_ParseFree(pParser, free);
  if (err) {
    *err = q->errorMsg;
  }

 
  return q->root;
}

