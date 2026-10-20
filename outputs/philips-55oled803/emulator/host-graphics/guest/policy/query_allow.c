/* Read-only TE allow inspection, including type attributes and active conditionals.
 * This is not a full access decision: MLS and class constraints remain separate. */
#include <sepol/policydb.h>
#include <sepol/policydb/policydb.h>
#include <stdio.h>
#include <stdlib.h>
static uint32_t inspect(policydb_t *p, avtab_t *table, int conditional, unsigned src,unsigned tgt,unsigned cls) {
 uint32_t mask=0;
 for(unsigned i=0;i<table->nslot;i++)for(avtab_ptr_t n=table->htable[i];n;n=n->next) {
  if(!(n->key.specified&AVTAB_ALLOWED)||n->key.target_class!=cls)continue;
  if(!ebitmap_get_bit(&p->type_attr_map[src-1],n->key.source_type-1)||!ebitmap_get_bit(&p->type_attr_map[tgt-1],n->key.target_type-1))continue;
  int active=!conditional||(n->key.specified&AVTAB_ENABLED);
  printf("match %s -> %s mask=%08x conditional=%d active=%d\n",p->p_type_val_to_name[n->key.source_type-1],p->p_type_val_to_name[n->key.target_type-1],n->datum.data,conditional,!!active);
  if(active)mask|=n->datum.data;
 }
 return mask;
}
int main(int argc,char **argv) {
 if(argc!=5)return 2;
 FILE *f=fopen(argv[1],"rb");if(!f)return 2;
 fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);void *buf=malloc(size);if(fread(buf,1,size,f)!=size)return 2;fclose(f);
 sepol_policydb_t *db; if(sepol_policydb_create(&db)||sepol_policydb_from_image(NULL,buf,size,db))return 2;
 policydb_t *p=&db->p;type_datum_t *s=hashtab_search(p->p_types.table,argv[2]),*t=hashtab_search(p->p_types.table,argv[3]);class_datum_t *c=hashtab_search(p->p_classes.table,argv[4]);if(!s||!t||!c)return 2;
 uint32_t mask=inspect(p,&p->te_avtab,0,s->s.value,t->s.value,c->s.value)|inspect(p,&p->te_cond_avtab,1,s->s.value,t->s.value,c->s.value);
 printf("union TE allow mask=%08x\n",mask);
 hashtab_t tables[]={c->permissions.table,c->comdatum?c->comdatum->permissions.table:NULL};
 for(int k=0;k<2;k++)if(tables[k])for(unsigned i=0;i<tables[k]->size;i++)for(hashtab_ptr_t n=tables[k]->htable[i];n;n=n->next){perm_datum_t *d=n->datum;printf("%s %s\n",n->key,mask&(1U<<(d->s.value-1))?"ALLOWED":"absent");}
 return 0;
}
