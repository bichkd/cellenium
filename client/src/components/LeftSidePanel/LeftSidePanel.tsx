import React, {useState} from 'react';
import {Anchor, createStyles, Group, Navbar, Title, Tooltip, UnstyledButton} from '@mantine/core';
import {ReactComponent as CellTypeMarkerIcon} from "../../icons/study_analysis.svg";
import {ReactComponent as ExpressionAnalysisIcon} from "../../icons/expression_analysis.svg";
import {ReactComponent as CoExpressionAnalysisIcon} from "../../icons/coexpression_analysis.svg";
import {ReactComponent as CompareAnnotationsIcon} from "../../icons/annotation_comparison.svg";
import {ReactComponent as UserAnnotationIcon} from "../../icons/user_annotation.svg";
import { redirect } from "react-router-dom";
import { useNavigate } from "react-router-dom";

import {ReactComponent as CelleniumLogo} from "../../images/logo.svg";

const useStyles = createStyles((theme) => ({
    wrapper: {
        display: 'flex',
    },

    aside: {
        flex: '0 0 60px',
        backgroundColor: theme.colorScheme === 'dark' ? theme.colors.dark[7] : theme.white,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        borderRight: `1px solid ${
            theme.colorScheme === 'dark' ? theme.colors.dark[7] : theme.colors.gray[3]
        }`,
    },

    main: {
        flex: 1,
        backgroundColor: theme.colorScheme === 'dark' ? theme.colors.dark[6] : theme.colors.gray[0],
    },

    navigation: {
        padding: theme.spacing.md,

    },
    mainLink: {
        width: 44,
        height: 44,
        borderRadius: theme.radius.md,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: theme.colorScheme === 'dark' ? theme.colors.dark[0] : theme.colors.gray[7],

        '&:hover': {
            backgroundColor: theme.colorScheme === 'dark' ? theme.colors.dark[5] : theme.colors.gray[0],
        },
    },

    mainLinkActive: {
        '&, &:hover': {
            backgroundColor: theme.fn.variant({variant: 'light', color: theme.colors.gray[4]}).background,
            color: theme.fn.variant({variant: 'light', color: theme.colors.gray[4]}).color,
        },
    },

    title: {
        boxSizing: 'border-box',
        fontFamily: `Exo-bold, ${theme.fontFamily}`,
        fontSize: '1.8rem',
        marginBottom: theme.spacing.md,
        backgroundColor: theme.colorScheme === 'dark' ? theme.colors.dark[7] : theme.white,
        paddingTop: 10,
        paddingLeft: 15,
        height: 60,
        borderBottom: `1px solid ${
            theme.colorScheme === 'dark' ? theme.colors.dark[7] : theme.colors.gray[3]
        }`,
    },

    logo: {
        boxSizing: 'border-box',
        width: '100%',
        display: 'flex',
        justifyContent: 'center',
        height: 60,
        paddingTop: theme.spacing.md,
        marginBottom: theme.spacing.md + 4,

        borderBottom: `1px solid ${
            theme.colorScheme === 'dark' ? theme.colors.dark[7] : theme.colors.gray[3]
        }`,

    },

}));

const viewLinks = [
    {icon: CellTypeMarkerIcon, label: 'Cell type marker analysis', value: 'cellmarkeranalysis'},
    {icon: ExpressionAnalysisIcon, label: 'Expression analysis', value: 'expressionanalysis'},
    {icon: CoExpressionAnalysisIcon, label: 'Co-Expression analysis', value: 'coexpressionanalysis'},
    {icon: CompareAnnotationsIcon, label: 'Compare annotations', value: 'annotationcomparison'},
    {icon: UserAnnotationIcon, label: 'User annotations', value: 'userannotation'},
];

type Props = {
    children?: React.ReactNode;
}

function LeftSidePanel({children}: Props) {
    const {classes, cx} = useStyles();
    const [active, setActive] = useState('Cell type marker analysis');
  const navigate = useNavigate();

    const mainLinks = viewLinks.map((link) => (
        <Tooltip label={link.label} position="right" withArrow transitionDuration={0} key={link.label}>
            <UnstyledButton
                onClick={() => {
                    setActive(link.label)
                    let url = `/${link.value}`;
                    console.log('going to ',url)

                    navigate(url)
                }}
                className={cx(classes.mainLink, {[classes.mainLinkActive]: link.label === active})}
            >
                <link.icon/>
            </UnstyledButton>
        </Tooltip>
    ));


    return (
        <Navbar height={'100vh'} width={{sm: 300}}>
            <Navbar.Section grow className={classes.wrapper}>
                <div className={classes.aside}>
                    <div className={classes.logo}>
                        <Anchor href={'/'}><CelleniumLogo/></Anchor>
                    </div>
                    {mainLinks}
                </div>
                <div className={classes.main}>
                    <Title order={4} className={classes.title}>
                        cellenium
                    </Title>
                    <Group className={classes.navigation} spacing={'md'}>
                        {children}
                    </Group>
                </div>
            </Navbar.Section>
        </Navbar>
    );
}

export {LeftSidePanel}