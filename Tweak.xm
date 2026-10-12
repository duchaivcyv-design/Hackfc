#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/mman.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <string.h>
#import <stdlib.h>

#define PT_TRACE_ME     0
#define PT_ATTACH      10
#define PT_DENY_ATTACH 31
extern int ptrace(int request, pid_t pid, caddr_t addr, int data);
extern int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

static BOOL gOn=YES, gCoin=YES, gGem=YES, gXP=YES, gStam=YES;
static BOOL gSpeed=NO, gAuto=NO, gUnlock=YES;
static BOOL gAnti=YES, gFrida=YES, gJB=YES, gDeb=YES;

static NSArray *prefKeys(void) {
    return @[@"on",@"coin",@"gem",@"xp",@"stam",@"speed",
             @"auto",@"unlock",@"anti",@"frida",@"jb",@"deb"];
}
static BOOL *prefPtrs[12] = {&gOn,&gCoin,&gGem,&gXP,&gStam,&gSpeed,
                             &gAuto,&gUnlock,&gAnti,&gFrida,&gJB,&gDeb};

static void __attribute__((unused)) prefSave(void) {
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

static UIWindow *gWin = nil;
static FCMView  *gView = nil;
static NSInteger      gCurrentTouches = 0;
static NSInteger      gMaxTouches     = 0;
static NSTimeInterval gTouchStart     = 0;
static NSTimeInterval gLastTap        = 0;

static void showMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gWin) { gWin.hidden = !gWin.hidden; return; }
        CGRect r = CGRectMake(0, 0, 300, 470);
        UIWindow *w = [[UIWindow alloc] initWithFrame:r];
        w.windowLevel = UIWindowLevelAlert + 1000;
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
        w.hidden = NO;
        [w makeKeyAndVisible];
    });
}

%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        NSSet *all = [event allTouches];
        NSInteger began = 0, ended = 0;
        for (UITouch *t in all) {
            if (t.phase == UITouchPhaseBegan) began++;
            else if (t.phase == UITouchPhaseEnded ||
                     t.phase == UITouchPhaseCancelled) ended++;
        }
        if (began > 0) {
            if (gCurrentTouches == 0)
                gTouchStart = [[NSDate date] timeIntervalSince1970];
            gCurrentTouches += began;
            if (gCurrentTouches > gMaxTouches) gMaxTouches = gCurrentTouches;
        }
        if (ended > 0) {
            gCurrentTouches -= ended;
            if (gCurrentTouches <= 0) {
                gCurrentTouches = 0;
                NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                NSTimeInterval dur = now - gTouchStart;
                if (gMaxTouches >= 3 && dur < 0.4) {
                    if (gLastTap > 0 && (now - gLastTap) < 0.6) {
                        gLastTap = 0;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (gWin) gWin.hidden = !gWin.hidden;
                            else showMenu();
                        });
                    } else {
                        gLastTap = now;
                    }
                }
                gMaxTouches = 0;
            }
        }
    }
    %orig;
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

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)req
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))h {
    NSString *u = [[req URL] absoluteString];
    if (gOn && gAnti && u &&
        ([u containsString:@"integrity"] ||
         [u containsString:@"anticheat"] ||
         [u containsString:@"attest"] ||
         [u containsString:@"jailbreak"])) {
        NSData *fake = [@"{\"status\":\"ok\",\"tampered\":false}" dataUsingEncoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *r = [[NSHTTPURLResponse alloc] initWithURL:[req URL]
                                                          statusCode:200
                                                         HTTPVersion:@"HTTP/1.1"
                                                        headerFields:nil];
        if (h) h(fake, r, nil);
        return nil;
    }
    return %orig;
}
%end

typedef int      (*stat_t)(const char *, struct stat *);
typedef int      (*access_t)(const char *, int);
typedef int      (*sysctl_t)(int *, u_int, void *, size_t *, void *, size_t);
typedef void    *(*dlopen_t)(const char *, int);
typedef int      (*ptrace_t)(int, pid_t, caddr_t, int);
typedef kern_return_t (*task_info_fn_t)(task_name_t, task_flavor_t, integer_t *, mach_msg_type_number_t *);
typedef int      (*csops_t)(pid_t, unsigned int, void *, size_t);
typedef uint32_t (*dyld_count_t)(void);
typedef const char *(*dyld_name_t)(uint32_t);
typedef char    *(*getenv_t)(const char *);
typedef FILE    *(*fopen_t)(const char *, const char *);

static stat_t         orig_stat          = NULL;
static access_t       orig_access        = NULL;
static sysctl_t       orig_sysctl        = NULL;
static dlopen_t       orig_dlopen        = NULL;
static ptrace_t       orig_ptrace        = NULL;
static task_info_fn_t orig_task_info     = NULL;
static csops_t        orig_csops         = NULL;
static dyld_count_t   orig_dyld_count    = NULL;
static dyld_name_t    orig_dyld_name     = NULL;
static getenv_t       orig_getenv        = NULL;
static fopen_t        orig_fopen         = NULL;

static int my_stat(const char *p, struct stat *b) {
    if (gOn && gJB && p) {
        const char *bad[] = {"/var/jb","/Applications/Cydia","/Library/MobileSubstrate",
                             "/usr/sbin/sshd","/etc/apt","Substrate","substitute",
                             "frida","cycript","fcintl",NULL};
        for (int i = 0; bad[i]; i++)
            if (strstr(p, bad[i])) return -1;
    }
    return orig_stat(p, b);
}

static int my_access(const char *p, int m) {
    if (gOn && gJB && p) {
        const char *bad[] = {"/var/jb","/Applications/Cydia","/Library/MobileSubstrate",
                             "/usr/sbin/sshd","frida","fcintl",NULL};
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

static int my_ptrace(int req, pid_t pid, caddr_t addr, int data) {
    if (gOn && gAnti) {
        if (req == PT_DENY_ATTACH) return 0;
        if (req == PT_ATTACH)      return 0;
        if (req == PT_TRACE_ME)    return 0;
    }
    return orig_ptrace(req, pid, addr, data);
}

static kern_return_t my_task_info(task_name_t t, task_flavor_t fi,
                                  integer_t *ti, mach_msg_type_number_t *cnt) {
    if (gOn && gAnti && fi == TASK_DYLD_INFO) {
        if (ti && cnt) memset(ti, 0, *cnt * sizeof(integer_t));
        return KERN_SUCCESS;
    }
    return orig_task_info(t, fi, ti, cnt);
}

static int my_csops(pid_t pid, unsigned int op, void *ud, size_t sz) {
    if (gOn && gAnti && op == 0) {
        if (ud) *(uint32_t *)ud = 0;
        return 0;
    }
    return orig_csops(pid, op, ud, sz);
}

static uint32_t my_dyld_count(void) {
    return orig_dyld_count();
}

static const char *my_dyld_name(uint32_t idx) {
    const char *name = orig_dyld_name(idx);
    if (gOn && gAnti && name) {
        if (strstr(name,"fcintl"))     return "";
        if (strstr(name,"Substrate"))  return "";
        if (strstr(name,"ellekit"))    return "";
        if (strstr(name,"substitute")) return "";
    }
    return name;
}

static char *my_getenv(const char *key) {
    if (gOn && gAnti && key) {
        const char *bad[] = {"DYLD_INSERT_LIBRARIES","Jailbroken","JB_ROOT",
                             "_MSSafeMode","MSHookIvar",NULL};
        for (int i = 0; bad[i]; i++) if (strcmp(key, bad[i]) == 0) return NULL;
    }
    return orig_getenv(key);
}

static FILE *my_fopen(const char *p, const char *m) {
    if (gOn && gAnti && p) {
        const char *bad[] = {"frida","substitute","Substrate",
                             "/var/jb","cycript","MobileSubstrate","fcintl",NULL};
        for (int i = 0; bad[i]; i++) if (strstr(p, bad[i])) return NULL;
    }
    return orig_fopen(p, m);
}

static void scrubEnv(void) {
    if (!gOn || !gAnti) return;
    unsetenv("DYLD_INSERT_LIBRARIES");
    unsetenv("Jailbroken");
    unsetenv("JB_ROOT");
    unsetenv("_MSSafeMode");
    unsetenv("MSHookIvar");
}

%ctor {
    prefLoad();

    MSHookFunction((void *)stat,   (void *)my_stat,   (void **)&orig_stat);
    MSHookFunction((void *)access, (void *)my_access, (void **)&orig_access);
    MSHookFunction((void *)sysctl, (void *)my_sysctl, (void **)&orig_sysctl);
    MSHookFunction((void *)dlopen, (void *)my_dlopen, (void **)&orig_dlopen);
    MSHookFunction((void *)ptrace, (void *)my_ptrace, (void **)&orig_ptrace);
    MSHookFunction((void *)task_info, (void *)my_task_info, (void **)&orig_task_info);
    MSHookFunction((void *)getenv, (void *)my_getenv, (void **)&orig_getenv);
    MSHookFunction((void *)fopen,  (void *)my_fopen,  (void **)&orig_fopen);

    void *h = dlopen("/usr/lib/libSystem.B.dylib", RTLD_NOW);
    if (h) {
        csops_t c = (csops_t)dlsym(h, "csops");
        if (c) MSHookFunction((void *)c, (void *)my_csops, (void **)&orig_csops);
    }

    MSHookFunction((void *)_dyld_image_count,
                   (void *)my_dyld_count, (void **)&orig_dyld_count);
    MSHookFunction((void *)_dyld_get_image_name,
                   (void *)my_dyld_name,  (void **)&orig_dyld_name);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_global_queue(0, 0), ^{
        while (1) {
            scrubEnv();
            sleep(3);
        }
    });

    NSLog(@"[fcintl] loaded");
}
