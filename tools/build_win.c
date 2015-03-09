/*
 * Small/tools/build_win.c
 *
 * (C) 2012-2013 Yafei Zheng
 * V0.0 2012-12-7 19:53:15
 *
 * Email: e9999e@163.com, QQ: 1039332004
 */

/*
 * ���ļ�����windows��ʹ�ã����ô��ļ���VC6.0�±������ɵ�*.exe�ļ�����OS��ģ����װ��һ�顣
 */

#include <stdio.h>
#include <string.h>

#define BUFF_SIZE 1024			// �������ֽ���

#define OFFSET_BOOT 32			// ���ļ���ʼ����ƫ����(�ֽ���),����ȥ��boot.s��as86����֮���MINIXͷ(32B)
#define OFFSET_HEAD 0x1000		// ȥ��headģ���0x1000B��GCCͷ����Linux-0.11�У���1024B����Ϊ��ʱ��GCC��
								// �ɵĿ�ִ���ļ��� a.out ��ʽ�ģ������õ�GCC(gcc 4.6.3 for Start OS)���ɵ�
								// �� ELF ��ʽ������ELF�ļ�ͷ����ο�ELF������ݡ�

int main(void)
{
	char buff[BUFF_SIZE] = {0};
	FILE *fp_head = NULL, *fp_boot = NULL, *fp_Image = NULL;
	int count = 0, size_os = 0;

	if(! ((fp_head=fopen("head","rb")) && (fp_boot=fopen("boot","rb")) && (fp_Image=fopen("Image","wb"))))
	{
		printf("Error: can't open some file!!!\n");
		printf("\npress Enter to exit...");
		getchar();
		return -1;
	}

	fseek(fp_boot,OFFSET_BOOT,SEEK_SET);
	fseek(fp_head,OFFSET_HEAD,SEEK_SET);

	for(; (count=fread(buff,1,sizeof(buff),fp_boot))>0; size_os+=count,fwrite(buff,count,1,fp_Image)) {}
	fclose(fp_boot);
	for(; (count=fread(buff,1,sizeof(buff),fp_head))>0; size_os+=count,fwrite(buff,count,1,fp_Image)) {}
	fclose(fp_head);
	fclose(fp_Image);
	
	printf("===OK!\nSize of OS is %d Bytes.\n",size_os);

	printf("\npress Enter to exit...");
	getchar();
	return 0;
}
