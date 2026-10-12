// fcintl — Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <dlfcn.h>
#import <string.h>
#import <mach-o/dyld.h>

// ===== state =====
static BOOL gOn=YES, gCoin=YES, gGem=YES, gXP=YES, gStam=YES;
static BOOL gSpeed=NO, gAuto=NO, gUnlock=YES;
static BOOL gAnti=YES, gFrida=YES, gJB=YES, gDeb=YES;

static NSArray *prefKeys(void) {
    return @[@"on",@"coin",@"gem",@"xp",@"stam",@"speed",
             @"auto",@"unlock",@"anti",@"frida",@"jb",@"deb"];
}
static BOOL *prefPtrs[12] = {&gOn,&gCoin,&gGem,&gXP,&gStam,&gSpeed,
                             &gAuto,&gUnlock,&gAnti,&gFrida,&gJB,&gDeb};

static void prefSave(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSArray *k = prefKeys();
    for (int i = 0; i < 12; i++)
        [d setBool:*prefPtrs[i] forKey:[@"fci_" stringByAppendingString:k[i]]];
    [d synchronize];
}
static void prefLoad(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSArray *k = prefKeys();
    for (int i = 0; i < 12; i++)
        *prefPtrs[i] = [d boolForKey:[@"fci_" stringByAppendingString:k[i]]];
}

// ===== UI =====
@interface FCMView : UIView
@end

@implementation FCMView {
    UIScrollView *_scroll;
    NSMutableArray *_switches;
}

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (!self) return nil;
    self.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.94];
    self.layer.cornerRadius = 18;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:0 green:1 blue:0.6 alpha:0.55].CGColor;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, f.size.width, 24)];
    title.text = @"olliE intl";
    title.textColor = [UIColor colorWithRed:0 green:1 blue:0.6 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:15];
    [self addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(f.size.width - 36, 8, 30, 30);
    [close setTitle:@"x" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    close.tintColor = [UIColor redColor];
    [close addTarget:self action:@selector(hideSelf) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];

    _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 44, f.size.width, f.size.height - 54)];
    _scroll.contentSize = CGSizeMake(f.size.width, 12 * 38 + 12);
    [self addSubview:_scroll];

    NSArray *names = @[@"Enabled",@"Coins",@"Gems",@"XP",@"Stamina",@"Speed",
                       @"AutoWin",@"Unlock All",@"Anti Check",@"Hide Frida",
                       @"Hide JB",@"Hide Deb"];
    NSArray *keys  = prefKeys();
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    _switches = [NSMutableArray array];
    for (int i = 0; i < (int)names.count; i++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(14, 6 + i*38, 180, 28)];
        l.text = names[i];
        l.textColor = [UIColor whiteColor];
        l.font = [UIFont systemFontOfSize:13];
        [_scroll addSubview:l];

        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(f.size.width - 68, 6 + i*38, 51, 28)];
        s.onTintColor = [UIColor colorWithRed:0 green:1 blue:0.6 alpha:1];
        s.tag = i;
        s.on = [d boolForKey:[@"fci_" stringByAppendingString:keys[i]]];
        [s addTarget:self action:@selector(flip:) forControlEvents:UIControlEventValueChanged];
        [_scroll addSubview:s];
        [_switches addObject:s];
    }
    return self;
}

- (void)flip:(UISwitch *)s {
    NSArray *keys = prefKeys();
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:s.on forKey:[@"fci_" stringByAppendingString:keys[s.tag]]];
    [d synchronize];
    prefLoad();
}

- (void)hideSelf { self.hidden = YES; }

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)ev {
    [super touchesBegan:touches withEvent:ev];
    [self.superview bringSubviewToFront:self];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)ev {
    UITouch *t = [touches anyObject];
    self.center = [t locationInView:self.superview];
}
@end

// ===== window + gesture =====
static UIWindow *gWin = nil;
static FCMView  *gView = nil;

static void showMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gWin) { gWin.hidden = !gWin.hidden; return; }
        CGRect r = CGRectMake(0, 0, 300, 470);
        UIWindow *w = [[UIWindow alloc] initWithFrame:r];
        w.windowLevel = UIWindowLevelAlert + 100;
        w.backgroundColor = [UIColor clearColor];
        w.center = CGPointMake([UIScreen mainScreen].bounds.size.width  / 2,
                               [UIScreen mainScreen].bounds.size.height / 2);
        gView = [[FCMView alloc] initWithFrame:w.bounds];
        [w addSubview:gView];

        UITapGestureRecognizer *hide = [[UITapGestureRecognizer alloc] initWithTarget:gView
                                                                               action:@selector(hideSelf)];
        hide.numberOfTouchesRequired = 3;
        hide.numberOfTapsRequired = 2;
        [w addGestureRecognizer:hide];

        gWin = w;
        [w makeKeyAndVisible];
    });
}

// dùng accessibilityIdentifier thay cho tag — UITapGestureRecognizer không có tag
static void attachTrigger(UIWindow *w) {
    if (!w) return;
    for (UIGestureRecognizer *g in w.gestureRecognizers) {
        if ([g.accessibilityIdentifier isEqualToString:@"fci-trigger"]) return;
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTouchesRequired = 3;
    tap.numberOfTapsRequired = 2;
    tap.accessibilityIdentifier = @"fci-trigger";
    [tap addTarget:[UIApplication sharedApplication]
            action:@selector(fciTrigger)];
    [w addGestureRecognizer:tap];
}

// ===== hooks =====
%hook UIApplication
%new
- (void)fciTrigger { showMenu(); }
%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    attachTrigger(self);
}
%end

%hook NSUserDefaults
- (id)objectForKey:(NSString *)k {
    id v = %orig;
    if (!gOn) return v;
    if (gCoin && [k containsString:@"coin"])    return @(9999999999);
    if (gGem  && [k containsString:@"gem"])     return @(9999999999);
    if (gXP   && [k containsString:@"exp"])     return @(99999999);
    if (gStam && [k containsString:@"stamina"]) return @(9999);
    return v;
}
- (NSInteger)integerForKey:(NSString *)k {
    NSInteger v = %orig;
    if (!gOn) return v;
    if (gCoin && [k containsString:@"coin"])    return 9999999999;
    if (gGem  && [k containsString:@"gem"])     return 9999999999;
    if (gXP   && [k containsString:@"exp"])     return 99999999;
    if (gStam && [k containsString:@"stamina"]) return 9999;
    return v;
}
%end

// ===== anti-check =====
typedef int  (*stat_t)(const char *, struct stat *);
typedef int  (*access_t)(const char *, int);
typedef int  (*sysctl_t)(int *, u_int, void *, size_t *, void *, size_t);
typedef void *(*dlopen_t)(const char *, int);

static stat_t   orig_stat   = NULL;
static access_t orig_access = NULL;
static sysctl_t orig_sysctl = NULL;
static dlopen_t orig_dlopen = NULL;

static int my_stat(const char *p, struct stat *b) {
    if (gOn && gJB && p) {
        const char *bad[] = {"/var/jb","/Applications/Cydia","/Library/MobileSubstrate",
                             "/usr/sbin/sshd","/etc/apt","Substrate","substitute",
                             "frida","cycript",NULL};
        for (int i = 0; bad[i]; i++)
            if (strstr(p, bad[i])) return -1;
    }
    return orig_stat(p, b);
}

static int my_access(const char *p, int m) {
    if (gOn && gJB && p) {
        const char *bad[] = {"/var/jb","/Applications/Cydia","/Library/MobileSubstrate",
                             "/usr/sbin/sshd","frida",NULL};
        for (int i = 0; bad[i]; i++)
            if (strstr(p, bad[i])) return -1;
    }
    return orig_access(p, m);
}

static int my_sysctl(int *n, u_int nl, void *o, size_t *os, void *ni, size_t oldlen) {
    int r = orig_sysctl(n, nl, o, os, ni, oldlen);
    if (gOn && gFrida && n && nl == 4 && n[0] == CTL_KERN && n[1] == KERN_PROC) {
        if (o && os) memset(o, 0, *os);
    }
    return r;
}

static void *my_dlopen(const char *p, int m) {
    if (gOn && gFrida && p && strstr(p, "frida")) return NULL;
    return orig_dlopen(p, m);
}

// ===== entry =====
%ctor {
    prefLoad();
    MSHookFunction((void *)stat,   (void *)my_stat,   (void **)&orig_stat);
    MSHookFunction((void *)access, (void *)my_access, (void **)&orig_access);
    MSHookFunction((void *)sysctl, (void *)my_sysctl, (void **)&orig_sysctl);
    MSHookFunction((void *)dlopen, (void *)my_dlopen, (void **)&orig_dlopen);
    NSLog(@"[fcintl] loaded");
}
