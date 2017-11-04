//
//  main.m
//  ProtoBuf_Demo
//
//  Created by Victor Zhang on 04/11/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netdb.h>
#import "Person.pbobjc.h"

NSData *  serialize();
void deserialize();

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        //1.创建socket
        int socketFD = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(6789);
        addr.sin_addr.s_addr = INADDR_ANY; //指定监听的ip，指定为INADDR_ANY时，表示监听所有的ip
        
        //2.绑定并监听
        int error = -1;
        error = bind(socketFD, (const struct sockaddr *)&addr, sizeof(addr));
        error = listen(socketFD, 5);
        printf("接收客户端连接中。。。\n");
        
        //3.接收客户端连接
        struct sockaddr_in peerAddr;
        socklen_t addrLen = sizeof(peerAddr);
        int clientSocketFD = accept(socketFD, (struct sockaddr *)&peerAddr, &addrLen);
        
        //4.接收数据
        void * buf = malloc(1024);
        size_t len = sizeof(buf);
        read(clientSocketFD, buf, 1024);
        NSData *recData = [NSData dataWithBytes:buf length:1024];
        deserialize(recData);
        
        //5.发送数据到客户端
        NSData *pendingData = serialize();
        ssize_t re = write(clientSocketFD, [pendingData bytes], pendingData.length);
        if (re == pendingData.length) {
            NSLog(@"发送成功！");
        }
        
        close(clientSocketFD);
        close(socketFD);
    }
    return 0;
}

//序列化数据
NSData * serialize()
{
    //1.先初始化一些值吧
    Person *person = [[Person alloc] init];
    person.name = @"Victor张 - 服务器";
    person.age = 24;
    person.height = 185;
    person.deviceType = Person_DeviceType_Android;
    
    Person_Result *p_result = [[Person_Result alloc] init];
    p_result.title = @"我的博客 - 服务器";
    p_result.URL = @"http://www.googleplus.party/";
    [person.resultsArray addObject:p_result];
    
    Person_Result *p_result1 = [[Person_Result alloc] init];
    p_result1.title = @"我的Facebook - 服务器";
    p_result1.URL = @"https://www.facebook.com/victor.john.92167789?ref=bookmarks";
    [person.resultsArray addObject:p_result1];
    
    Animal *animal = [[Animal alloc] init];
    animal.price = 109;
    animal.name = @"Ketty - 服务器";
    [person.animalsArray addObject:animal];
    
    //序列化后的二进制数据
    NSData *data = [person delimitedData];
    
    return data;
}

//反序列化数据
void deserialize(NSData *data)
{
    //将二进制数据反序列化成对象
    NSError *error = nil;
    GPBCodedInputStream *inputStream = [GPBCodedInputStream streamWithData:data];
    Person *de_person = [Person parseDelimitedFromCodedInputStream:inputStream extensionRegistry:nil error:&error];
    NSLog(@"接受到数据，并反序列化：%@", de_person);
}
