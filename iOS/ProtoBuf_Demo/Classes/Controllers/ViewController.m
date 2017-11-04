//
//  ViewController.m
//  ProtoBuf_Demo
//
//  Created by Victor Zhang on 04/11/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netdb.h>
#import "Person.pbobjc.h"

@interface ViewController ()

@property (nonatomic, assign) int socketFD;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //1.先连接上socket
    self.socketFD = socket(AF_INET, SOCK_STREAM, 0);
    
    struct hostent * remoteHostEnt = gethostbyname("127.0.0.1");
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET;
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons(6789);
    
    int ret = connect(self.socketFD, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (-1 == ret) {
        close(self.socketFD);
        NSLog(@"连接socket失败！");
        return;
    }
    NSLog(@"已经连接上服务器！");
    
    [self serialize];
    [self deserialize];
}

//序列化
- (void)serialize
{
    //1.先初始化一些值吧
    Person *person = [[Person alloc] init];
    person.name = @"Victor张";
    person.age = 25;
    person.height = 175;
    person.deviceType = Person_DeviceType_Ios;
    
    Person_Result *p_result = [[Person_Result alloc] init];
    p_result.title = @"我的博客";
    p_result.URL = @"http://www.googleplus.party/";
    [person.resultsArray addObject:p_result];
    
    Person_Result *p_result1 = [[Person_Result alloc] init];
    p_result1.title = @"我的Facebook";
    p_result1.URL = @"https://www.facebook.com/victor.john.92167789?ref=bookmarks";
    [person.resultsArray addObject:p_result1];
    
    Animal *animal = [[Animal alloc] init];
    animal.price = 109;
    animal.name = @"Ketty";
    [person.animalsArray addObject:animal];
    
    //序列化后的二进制数据
    NSData *data = [person delimitedData];
    
    //向socket通道写入二进制数据
    ssize_t re = write(self.socketFD, [data bytes], data.length);
    if (re == data.length) {
        NSLog(@"发送成功！");
    }
}

//反序列化
- (void)deserialize
{
    //从socket通道中接收数据
    void * buf = malloc(1024);
    size_t len = sizeof(buf);
    read(self.socketFD, buf, 1024);
    NSData *data = [NSData dataWithBytes:buf length:1024];
    
    
    //将二进制数据反序列化成对象
    NSError *error = nil;
    GPBCodedInputStream *inputStream = [GPBCodedInputStream streamWithData:data];
    Person *de_person = [Person parseDelimitedFromCodedInputStream:inputStream extensionRegistry:nil error:&error];
    NSLog(@"%@", de_person);
    
    //关闭socket
    close(self.socketFD);
}


@end






