//
//  ViewController.m
//  Image2D
//
//  Created by apple on 15/10/15.
//  Copyright (c) 2015年 diveinedu. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZBarSDK.h"

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    UIImageView *_ORCodeImageView;
    AVCaptureSession *_captureSession;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self ORCodeImageViewInit];
    NSString *str = @"http://www.baidu.com";
    _ORCodeImageView.image = [self image:[self generateORCodeFromString:str] scale:10];
    
    [self scanImage:_ORCodeImageView.image];
    [self scanORCodeByAVFoundation];
}

#pragma mark Init
- (void)ORCodeImageViewInit{
    _ORCodeImageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 100, 100)];
    _ORCodeImageView.center = self.view.center;
    [self.view addSubview:_ORCodeImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark generate ORCode By CIFilter
//系统生成的二维码，原始image较小，图片模糊
- (UIImage *)generateORCodeFromString:(NSString *)string{
    //1. 需要⽣生成⼆二维码的内容
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding ];
    //2. ⼆二维码⽣生成器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //3. 设置输⼊入参数
    [filter setValue:stringData forKey:@"inputMessage"]; //4. 设置识别率
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    //5. 获取⽣生成的图⽚片
    CGImageRef cgImage = [[CIContext contextWithOptions:nil]
                          createCGImage:[filter outputImage]
                          fromRect:[[filter outputImage]extent]];
    return [UIImage imageWithCGImage:cgImage];
}

//经过加工处理图片，使图片清晰
- (UIImage *)image:(UIImage *)image scale:(CGFloat)scale {
    CGSize size = image.size;
    //1. 缩放图⽚片,使⽣生成的⼆二维码变得更清晰
    UIGraphicsBeginImageContext(CGSizeMake(size.width * scale, size.width *scale));
    CGContextRef context = UIGraphicsGetCurrentContext();
    //2. 插值
    CGContextSetInterpolationQuality(context, kCGInterpolationNone); //3. 绘制图⽚片
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context),image.CGImage);
    //4. 获取图⽚片
    UIImage *preImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //5. 旋转图⽚片
    UIImage *qrImage = [UIImage imageWithCGImage:[preImage CGImage]
                                           scale:[preImage scale]
                                     orientation:UIImageOrientationDownMirrored];
    return qrImage;
}

#pragma mark scan ORCode Image By ZBarSDK
- (void)scanImage:(UIImage *)image {
    //1. 需要识别的图⽚片对象
    ZBarImage *zImage = [[ZBarImage alloc]
                         initWithCGImage:image.CGImage]; //2. 图⽚片识别器
    ZBarImageScanner *imageScanner = [[ZBarImageScanner alloc]
                                      init];
    //3. 识别图⽚片⼆二维码
    [imageScanner scanImage:zImage];
    //4. 获取⼆二维码信息
    for (ZBarSymbol *symbol in zImage.symbols) {
        NSLog(@"%@", symbol.data);
    }
}

#pragma mark AVFoundation
//输入设备
- (void)AVCaptureInput{
    //1. 输⼊入设备
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if (!input) {
        return; }
    _captureSession = [[AVCaptureSession alloc]init];
    //2. 添加输⼊入设备
    [_captureSession addInput:input];
}

//输出设备
- (void)AVCaptureOutput{
    //3. 输出设备
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    dispatch_queue_t queue = dispatch_get_main_queue();
    //4. 添加输出
    [_captureSession addOutput:output];
    //设置代理,识别后调⽤用
    [output setMetadataObjectsDelegate:self queue:queue];   //5. 可⽤用的数据类型
    NSLog(@"%@", output.availableMetadataObjectTypes);      //6. 识别QRCode
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
}

//显示预览
- (void)displayScan{
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    previewLayer.frame = CGRectMake(100, 100, 200, 200);
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:previewLayer];
    
    //开始识别
    [_captureSession startRunning];
}
//delegate
//识别的输出⽅方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"%@", metadataObjects);
}

//All
- (void)scanORCodeByAVFoundation{
    [self AVCaptureInput];
    [self AVCaptureOutput];
    [self displayScan];
}

@end
