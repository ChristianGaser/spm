/* spm_getdata.c */
ifndef lint
static char sccsid[] = "%W% John Ashburner & Matthew Brett %E%";
#endif
/* routines for accessing datatypes for images */

short getshort(x)
short x;
{
	char *p1, *p2; short y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[1] = p1[0]; p2[0] = p1[1];
	return(y);
}

short getushort(x)
unsigned short x;
{
	char *p1, *p2; unsigned short y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[1] = p1[0]; p2[0] = p1[1];
	return(y);
}

int getint(x)
int x;
{
	char *p1, *p2; int y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[3] = p1[0]; p2[2] = p1[1];
	p2[1] = p1[2]; p2[0] = p1[3];
	return(y);
}

int getuint(x)
unsigned int x;
{
	char *p1, *p2; unsigned int y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[3] = p1[0]; p2[2] = p1[1];
	p2[1] = p1[2]; p2[0] = p1[3];
	return(y);
}

float getfloat(x)
float x;
{
	char *p1, *p2; float y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[3] = p1[0]; p2[2] = p1[1];
	p2[1] = p1[2]; p2[0] = p1[3];
	return(y);
}

double getdouble(x)
double x;
{
	char *p1, *p2; double y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[7] = p1[0]; p2[6] = p1[1];
	p2[5] = p1[2]; p2[4] = p1[3];
	p2[3] = p1[4]; p2[2] = p1[5];
	p2[1] = p1[6]; p2[0] = p1[7];
	return(y);
}

